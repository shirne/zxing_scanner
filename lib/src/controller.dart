import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/zxing.dart';

class ScanController extends ValueNotifier<List<Result>> {
  ScanState? state;

  ScanController() : super([]);

  void attach(ScanState state) {
    this.state = state;
  }

  Future<void> start() async {
    return state?.start();
  }

  Future<void> stop() async {
    return state?.stop();
  }

  Future<void> setFlashMode(FlashMode mode) async {
    return state?.setFlashMode(mode);
  }
}

abstract class ScanState {
  Future<void> start();
  Future<void> stop();

  setFlashMode(FlashMode mode);
}
