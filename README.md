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
  lat_hdr_transcoder_v2: ^1.0.0+4
```

# Android

```transcoding``` supported 29+
<br/>
Add provider under <application> in AndroidManifest.xml
```
<provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.provider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/provider_paths" />
</provider>
```
create res/xml/file_paths.xml
```
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-path
        name="external"
        path="." />
    <external-files-path
        name="external_files"
        path="." />
    <cache-path
        name="cache"
        path="." />
    <external-cache-path
        name="external_cache"
        path="." />
    <files-path
        name="files"
        path="." />
</paths>
```


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