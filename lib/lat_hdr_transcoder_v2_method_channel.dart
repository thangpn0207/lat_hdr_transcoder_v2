import 'package:flutter/services.dart';

import 'lat_hdr_transcoder_v2_platform_interface.dart';

/// An implementation of [LatHdrTranscoderV2Platform] that uses method channels.
class MethodChannelLatHdrTranscoderV2 extends LatHdrTranscoderV2Platform {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('lat_hdr_transcoder_v2');

  static const _progressStream = EventChannel('lat_hdr_transcoder_v2_event');

  Stream<double>? _onProgress;

  // Returns the transcoding rate in progress
  // 0.0 to 1.0
  @override
  Stream<double> onProgress() {
    _onProgress ??= _progressStream
        .receiveBroadcastStream()
        .map<double>((dynamic value) => value ?? 0);
    return _onProgress!;
  }

  @override
  Future<bool?> clearCache() {
    return _methodChannel.invokeMethod<bool>('clearCache');
  }

  @override
  Future<bool?> isHdr(String path) {
    return _methodChannel.invokeMethod<bool>('isHDR', {'path': path});
  }

  @override
  Future<String?> transcoding(String path) {
    return _methodChannel.invokeMethod<String>('transcoding', {'path': path});
  }
}
