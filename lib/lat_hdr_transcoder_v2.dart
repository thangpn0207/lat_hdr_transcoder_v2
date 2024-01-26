import 'lat_hdr_transcoder_v2_platform_interface.dart';

class LatHdrTranscoderV2 {
  // Convert the HDR video file to SDR
  // Make sure it is HDR before converting
  Future<String?> transcoding(String path) {
    return LatHdrTranscoderV2Platform.instance.transcoding(path);
  }

  // Make sure the video file is in HDR format
  Future<bool?> isHdr(String path) {
    return LatHdrTranscoderV2Platform.instance.isHdr(path);
  }

  // Video files converted to SDR are accumulated in a temporary folder
  // It is the developer's responsibility to delete the cache files
  // Delete them at the appropriate time to avoid running out of space on user device
  Future<bool?> cleanCache() {
    return LatHdrTranscoderV2Platform.instance.clearCache();
  }

  Stream<double> onProgress() {
    return LatHdrTranscoderV2Platform.instance.onProgress();
  }
}
