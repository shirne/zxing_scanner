import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:zxing_lib/zxing.dart';

import 'controller.dart';
import 'foundation/scan_stream.dart';

/// create a scan widget to capture and show camera
class ScanView extends StatefulWidget {
  /// constructor
  const ScanView({
    super.key,
    this.child,
    this.autoStart = true,
    this.flashMode = FlashMode.off,
    this.onError,
    this.onResult,
    this.controller,
  });

  /// child element to cover camera view
  final Widget? child;

  /// auto start capture and decode
  final bool autoStart;

  /// flash Mode
  final FlashMode flashMode;

  /// error callback
  final Function(dynamic)? onError;

  /// result callback
  final Function(List<Result>)? onResult;

  /// capture controller
  final ScanController? controller;

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> implements ScanState {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final _isoController = IsolateController();
  bool isDetectedCamera = false;
  bool isDetecting = false;
  bool isStop = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    Future.wait([
      initCamera(),
      _isoController.start(),
      Future.delayed(const Duration(seconds: 1)),
    ]).then((value) {
      if (widget.autoStart) {
        start();
      }
    });
  }

  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();
      var camera = _cameras!.first;
      for (var c in _cameras!) {
        if (c.lensDirection == CameraLensDirection.back) {
          camera = c;
        }
      }

      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          camera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _controller!.initialize();
        if (!mounted) {
          return;
        }

        await _controller!.setFlashMode(widget.flashMode);

        setState(() {
          isDetectedCamera = true;
        });
      } else {
        widget.onError?.call(Exception('Undetected camera'));
        setState(() {
          isDetectedCamera = true;
        });
      }
    } catch (e) {
      widget.onError?.call(e);
      setState(() {
        isDetectedCamera = true;
      });
    }
  }

  bool _isStart = false;
  @override
  Future<void> start() async {
    if (_isStart || !mounted) return;
    _isStart = true;
    await _controller!.startImageStream(tryDecodeImage);
  }

  @override
  Future<void> stop() async {
    if (!_isStart) return;
    _isStart = false;
    await _controller!.stopImageStream();
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    return _controller?.setFlashMode(mode);
  }

  Future<void> tryDecodeImage(CameraImage image) async {
    if (isDetecting || !mounted) return;
    setState(() {
      isDetecting = true;
    });

    await stop();

    try {
      final results = await _isoController.setPlanes(image.planes);
      if (!mounted) return;
      setState(() {
        isDetecting = false;
      });

      widget.onResult?.call(results);
      widget.controller?.value = results;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isDetecting = false;
      });

      Future.delayed(Duration.zero).then((_) {
        start();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: _controller == null
          ? Center(child: Text(isDetectedCamera ? '未检测到摄像头' : '正在检测摄像头'))
          : CameraPreview(
              _controller!,
              child: widget.child,
            ),
    );
  }
}
