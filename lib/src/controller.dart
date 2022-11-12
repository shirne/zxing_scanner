import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/zxing.dart';

/// Scan controller to start/stop set flashMode
class ScanController extends ValueNotifier<List<Result>> {
  ScanState? _state;

  /// constructor
  ScanController() : super([]);

  /// atatch to a state
  void attach(ScanState state) {
    _state = state;
  }

  /// start capture
  Future<void> start() async {
    return _state?.start();
  }

  /// stop capture
  Future<void> stop() async {
    return _state?.stop();
  }

  /// set flashMode
  Future<void> setFlashMode(FlashMode mode) async {
    return _state?.setFlashMode(mode);
  }
}

/// An abstract scan state
abstract class ScanState {
  /// start capture
  Future<void> start();

  /// stop capture
  Future<void> stop();

  /// set flashMode
  Future<void> setFlashMode(FlashMode mode);
}
