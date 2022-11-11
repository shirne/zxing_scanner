import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:zxing_lib/zxing.dart';

import 'scan_image.dart';

Future<List<Result>?> scanImage(Uint8List data) async {
  final ui.Image image = await decodeImageFromList(data);
  final byteData = await image.toByteData();
  if (byteData == null) {
    return null;
  }
  return decodeImageInIsolate(
    byteData.buffer.asUint8List(),
    image.width,
    image.height,
  );
}
