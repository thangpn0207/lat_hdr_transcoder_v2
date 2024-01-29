package com.transcoder.lat_hdr_transcoder_v2.lat_hdr_transcoder_v2

import android.content.Context
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import androidx.annotation.NonNull
import androidx.annotation.OptIn
import androidx.core.content.FileProvider
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.*
import androidx.media3.transformer.Transformer.PROGRESS_STATE_NOT_STARTED

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File


/** LatHdrTranscoderV2Plugin */
class LatHdrTranscoderV2Plugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  companion object {
    const val TAG = "LatHdrTranscoderPlugin"
  }

  private lateinit var context: Context

  private val sdrDirName = "_sdr_"
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  private fun log(value: String) {
    // Log.d(TAG, value)
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "lat_hdr_transcoder_v2")
    channel.setMethodCallHandler(this)

    eventChannel =
      EventChannel(flutterPluginBinding.binaryMessenger,
        "lat_hdr_transcoder_v2_event")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    log("${call.method}, ${call.arguments}")
    when (call.method) {
      "isHDR" -> {
        val path = call.argument<String?>("path")
        if (path == null) {
          TranscoderErrorType.InvalidArgs.occurs(result)
          return
        }
        isHDR(path, result)
      }
      "clearCache" -> {
        result.success(clearCache())
      }

      "transcoding" -> {
        val path = call.argument<String?>("path")
        val toneMap = call.argument<Int?>("toneMap")

        if (path == null) {
          TranscoderErrorType.InvalidArgs.occurs(result)
          return
        }
        if (Build.VERSION.SDK_INT < 29) {
          TranscoderErrorType.NotSupportVersion.occurs(result)
          return
        }
        transcoding(path,toneMap, result)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun isHDR(path: String, @NonNull result: Result) {
    val extractor = MediaExtractor()
    extractor.setDataSource(path)
    val trackLength = extractor.trackCount - 1;
    log("track count: $trackLength")

    var isHdr = false
    for (i in 0..trackLength) {
      val format = extractor.getTrackFormat(i)

      var colorStandard: Int = -1
      var colorTransfer: Int = -1
      if (format.containsKey(MediaFormat.KEY_COLOR_STANDARD)) {
        colorStandard = format.getInteger(MediaFormat.KEY_COLOR_STANDARD)
        log("color standard: result: $colorStandard == ${MediaFormat.COLOR_STANDARD_BT2020}")
      }

      if (format.containsKey(MediaFormat.KEY_COLOR_TRANSFER)) {
        colorTransfer = format.getInteger(MediaFormat.KEY_COLOR_TRANSFER)
        log("color transfer: result: $colorTransfer == ${MediaFormat.COLOR_TRANSFER_ST2084} || ${MediaFormat.COLOR_TRANSFER_HLG}")
      }

      if (colorStandard == MediaFormat.COLOR_STANDARD_BT2020 &&
        (colorTransfer == MediaFormat.COLOR_TRANSFER_ST2084 || colorTransfer == MediaFormat.COLOR_TRANSFER_HLG)
      ) {
        isHdr = true
        break
      }
    }

    result.success(isHdr)
  }

  @OptIn(UnstableApi::class) private fun transcoding(path: String,toneMapRequest: Int?, @NonNull result: Result) {
    val inputUri = uriFromFilePath(path)
    val outputPath = createOutputPath(path)
    log("input: $path")
    log("output: $outputPath")
    deleteFile(outputPath)
    var toneMap = hdrToneMap()
    if (toneMapRequest != null) toneMap = toneMapRequest
    if (toneMap == -1) {
      TranscoderErrorType.NotSupportVersion.occurs(result)
      return
    }
    val editedMediaItem =
      EditedMediaItem.Builder(MediaItem.fromUri(inputUri))
        .setFlattenForSlowMotion(true).build()
    val composition = Composition.Builder(EditedMediaItemSequence(editedMediaItem))
      .setHdrMode(toneMap)
      .build()

    val transformerOnListener = object : Transformer.Listener {
      override fun onError(
        composition: Composition,
        exportResult: ExportResult,
        exportException: ExportException
      ) {

        log("${exportException.errorCode} ${exportException.errorCodeName}")
        // TranscodeErrorType.FailedTranscode.occurs(result, exportException.errorCodeName)
        result.success(null)
      }

      override fun onCompleted(composition: Composition, exportResult: ExportResult) {
        log("completed: $outputPath")
        eventSink?.success(1.0)
        result.success(outputPath)
      }
    }

    val transformer = Transformer.Builder(context)
      .addListener(transformerOnListener)
      .build()
    transformer.start(composition, outputPath)

    var currentProgress = 0.0
    eventSink?.success(0.0)
    val progressHolder = ProgressHolder()
    val handler = Handler(context.mainLooper)
    handler.post(object : Runnable {
      @OptIn(UnstableApi::class) override fun run() {
        val state = transformer.getProgress(progressHolder)
        if (state != PROGRESS_STATE_NOT_STARTED) {
          val current = progressHolder.progress * 0.01
          if (current != currentProgress
          ) {
            currentProgress = current
            log("$currentProgress")
            eventSink?.success(currentProgress)
          }
          handler.postDelayed(this, 100)
        }
      }
    })
  }

  @UnstableApi private fun hdrToneMap(): Int {
    return if (Build.VERSION.SDK_INT >= 33) {
      Composition.HDR_MODE_TONE_MAP_HDR_TO_SDR_USING_MEDIACODEC
    } else if (Build.VERSION.SDK_INT >= 29) {
      Composition.HDR_MODE_TONE_MAP_HDR_TO_SDR_USING_OPEN_GL
    } else {
      -1
    }
  }

  private fun sdrDirectory(): File {
    return File(context.getExternalFilesDir("lat_hdr"), sdrDirName)
  }

  private fun clearCache(): Boolean {
    if (sdrDirectory().exists()) {
      return sdrDirectory().deleteRecursively()
    }
    return true
  }

  private fun createOutputPath(path: String): String {
    val uri = Uri.parse(path)
    val fileName = uri.lastPathSegment

    val name = fileName?.substringBeforeLast(".")
    val ext = fileName?.substringAfterLast(".")
    val newFileName = "${name}_sdr.${ext}"

    val sdrDir = sdrDirectory()
    if (!sdrDir.exists()) {
      sdrDir.mkdir()
    }
    return sdrDir.absolutePath + "/" + newFileName
  }

  private fun deleteFile(path: String) {
    val file = File(path)
    file.exists().let {
      if (it) {
        file.delete()
      }
    }
  }

  private fun uriFromFilePath(path: String): Uri {
    return FileProvider.getUriForFile(
      context,
      context.packageName + ".provider",
      File(path)
    )
  }
}
