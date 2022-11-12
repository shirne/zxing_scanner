# ZXing Scanner(Dart)
[![pub package](https://img.shields.io/pub/v/zxing_scanner.svg)](https://pub.dartlang.org/packages/zxing_scanner)


A Barcode scanner Widget that can be embedded inside flutter. It uses zxing-dart for all platforms.

| | |
|:---:|:---:|
|ZXing Dart|[![pub package](https://img.shields.io/pub/v/zxing_lib.svg)](https://pub.dartlang.org/packages/zxing_lib)|
|ZXing Widget|[![pub package](https://img.shields.io/pub/v/zxing_widget.svg)](https://pub.dartlang.org/packages/zxing_widget)|
|ZXing Scanner|[![pub package](https://img.shields.io/pub/v/zxing_scanner.svg)](https://pub.dartlang.org/packages/zxing_scanner)|

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

This package depends on [zxing_lib](https://pub.dartlang.org/packages/zxing_lib) witch is a pure dart port of ZXing.
