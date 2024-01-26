# lat_hdr_transcoder_v2


[![pub package](https://img.shields.io/pub/v/lat_hdr_transcoder_v2.svg)](https://pub.dartlang.org/packages/lat_hdr_transcoder_v2)


The purpose of this plugin is clear and simple

It checks if the video file is in HDR format and converts HDR video to SDR<br/>
The conversion utilizes the capabilities of the native platform (Android, iOS)<br/>
(FFMPEG is not utilized)

Be sure to check the minimum supported version

<br/>

# Getting started

```yaml
dependencies:
  lat_hdr_transcoder_v2: ^1.0.0+1
```

# Android

```transcoding``` supported 29+


# iOS

```isHdr``` supported 14+



# How to use

## Check HDR format
```dart
bool isHdr = await LatHdrTranscoderV2().isHdr(String path)
```

## Transcoding
```dart
Stream<double> stream = LatHdrTranscoderV2().onProgress()
stream.listen(double value) {
  print(value) // 0.0 to 1.0
}
String? sdrVideoPath = await LatHdrTranscoderV2().transcoding(String path)
```

## Clear cache
```dart
bool success = await LatHdrTranscoderV2().clearCache()
```