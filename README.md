ZXing Scanner(Dart)


A Barcode scanner Widget that can be embedded inside flutter. It uses zxing-dart for all platforms.

## Features

- ✅ Scan from camera (Supported Android,IOS, Web)*
- ✅ Scan from Image file

* Scan from camera need camera support for platform. and camera plugin now supported android,ios, and web.
and on some mobile devices browsers there's error while fetch cameras. see [camera fix for web](git@github.com:shirne/plugins.git)

## Getting started

flutter pub add zxing_scanner

## Usage

See `/example` folder.

Scan from camera
```dart
ScanView(
    onResult: (List<Result> results),
),
```
Scan from image file
```dart
List<Result> results = await scanImage(await file.readAsBytes());
```

## Additional information

This package depends on [zxing_lib](https://pub.flutter-io.cn/packages/zxing_lib) witch is a pure dart port of ZXing.
