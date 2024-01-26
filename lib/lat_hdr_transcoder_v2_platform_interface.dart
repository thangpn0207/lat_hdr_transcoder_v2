import 'lat_hdr_transcoder_v2_method_channel.dart';

abstract class LatHdrTranscoderV2Platform {
  static LatHdrTranscoderV2Platform instance =
      MethodChannelLatHdrTranscoderV2();

  // Make sure the video file is in HDR format
  Future<bool?> isHdr(String path);
  // Convert the HDR video file to SDR
  // Make sure it is HDR before converting
  Future<String?> transcoding(String path);

  // Video files converted to SDR are accumulated in a temporary folder
  // It is the developer's responsibility to delete the cache files
  // Delete them at the appropriate time to avoid running out of space on user device
  Future<bool?> clearCache();

  Stream<double> onProgress();
}
