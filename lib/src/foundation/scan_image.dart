import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/zxing.dart';

class IsoMessage {
  final SendPort? sendPort;
  final Uint8List byteData;
  final int width;
  final int height;

  IsoMessage(this.sendPort, this.byteData, this.width, this.height);
}

Future<List<Result>?> decodeImageInIsolate(
  Uint8List image,
  int width,
  int height, {
  bool isRgb = true,
}) async {
  if (kIsWeb) {
    return isRgb
        ? decodeImage(IsoMessage(null, image, width, height))
        : decodeCamera(IsoMessage(null, image, width, height));
  }
  var complete = Completer<List<Result>?>();
  var port = ReceivePort();
  port.listen(
    (message) {
      if (!complete.isCompleted) {
        complete.complete(message as List<Result>?);
      }
      port.close();
    },
    onDone: () {},
    onError: (error) {},
  );

  IsoMessage message = IsoMessage(port.sendPort, image, width, height);
  if (isRgb) {
    Isolate.spawn<IsoMessage>(decodeImage, message, debugName: "decodeImage");
  } else {
    Isolate.spawn<IsoMessage>(decodeCamera, message, debugName: "decodeCamera");
  }

  return complete.future;
}

Uint8List color2Uint(int color) {
  return Uint8List.fromList([
    color >> 16 & 0xff,
    color >> 8 & 0xff,
    color & 0xff,
    color >> 16 & 0xff
  ]);
}

int getColor(int r, int g, int b, [int a = 255]) {
  return (r << 16) + (g << 8) + b + (a << 24);
}

int getColorFromByte(List<int> byte, int index, {bool isLog = false}) {
  if (byte.length <= index + 3) {
    return 0xffffffff;
  }
  return getColor(
    byte[index],
    byte[index + 1],
    byte[index + 2],
    byte[index + 3],
  );
}

int getLuminanceSourcePixel(List<int> byte, int index) {
  if (byte.length <= index + 3) {
    return 0xff;
  }
  final r = byte[index] & 0xff; // red
  final g2 = (byte[index + 1] << 1) & 0x1fe; // 2 * green
  final b = byte[index + 2]; // blue
  // Calculate green-favouring average cheaply
  return ((r + g2 + b) ~/ 4);
}

List<Result>? decodeImage(IsoMessage message) {
  final pixels = Uint8List(message.width * message.height);
  for (int i = 0; i < pixels.length; i++) {
    pixels[i] = getLuminanceSourcePixel(message.byteData, i * 4);
  }

  final imageSource = RGBLuminanceSource.orig(
    message.width,
    message.height,
    pixels,
  );

  final bitmap = BinaryBitmap(HybridBinarizer(imageSource));

  final reader = GenericMultipleBarcodeReader(MultiFormatReader());
  try {
    var results = reader.decodeMultiple(bitmap, {
      DecodeHintType.TRY_HARDER: true,
      DecodeHintType.ALSO_INVERTED: true,
    });

    message.sendPort?.send(results);
    return results;
  } on NotFoundException catch (_) {
    message.sendPort?.send(null);
  }
  return null;
}

List<Result>? decodeCamera(IsoMessage message) {
  final imageSource = PlanarYUVLuminanceSource(
    message.byteData.buffer.asUint8List(),
    message.width,
    message.height,
  );

  final bitmap = BinaryBitmap(HybridBinarizer(imageSource));
  final reader = GenericMultipleBarcodeReader(MultiFormatReader());
  try {
    final results = reader.decodeMultiple(bitmap, {
      DecodeHintType.TRY_HARDER: false,
      DecodeHintType.ALSO_INVERTED: false,
    });
    message.sendPort?.send(results);
    return results;
  } on NotFoundException catch (_) {
    message.sendPort?.send(null);
  }
  return null;
}
