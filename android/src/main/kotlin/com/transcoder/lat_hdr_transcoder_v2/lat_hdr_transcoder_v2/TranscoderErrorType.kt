package com.transcoder.lat_hdr_transcoder_v2.lat_hdr_transcoder_v2
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel

enum class TranscoderErrorType (private val rawValue: Int) {
    InvalidArgs(0),
    NotSupportVersion(1),
    ExistsOutputFile(2),
    FailedTranscode(3);

    private val code: String
        get() = "$rawValue"

    private fun message(extra: String?): String {
        return when (this) {
            InvalidArgs -> "argument are not valid"
            NotSupportVersion -> "os version is not supported: $extra"
            ExistsOutputFile -> "output file exists: $extra"
            FailedTranscode -> "failed transcode error: $extra"
        }
    }

    fun occurs(@NonNull result: MethodChannel.Result, extra: String? = null) {
        result.error(code, message(extra), null)
    }
}