import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:zxing_lib/zxing.dart';

import 'controller.dart';
import 'foundation/scan_image.dart';

/// scan view for platforms that not suppert camera stream capture
class ScanViewWeb extends StatefulWidget {
  /// constructor
  const ScanViewWeb({
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
  State<ScanViewWeb> createState() => _ScanViewWebState();
}

class _ScanViewWebState extends State<ScanViewWeb> implements ScanState {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool isDetectedCamera = false;
  bool isDetecting = false;
  bool isStop = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras!.isNotEmpty) {
        var camera = _cameras!.first;
        for (var c in _cameras!) {
          if (c.lensDirection == CameraLensDirection.back) {
            camera = c;
          }
        }
        _controller = CameraController(
          camera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        _controller!.initialize().then((_) async {
          if (!mounted) {
            return;
          }

          await _controller!.setFlashMode(widget.flashMode);

          setState(() {
            isDetectedCamera = true;
          });
          if (widget.autoStart) {
            Future.delayed(Duration.zero).then((value) => onCameraView());
          }
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

  @override
  Future<void> start() {
    isStop = false;
    return onCameraView();
  }

  @override
  Future<void> stop() async {
    isStop = true;
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    return _controller?.setFlashMode(mode);
  }

  ui.Image? image;
  Future<void> onCameraView() async {
    if (isDetecting || !mounted) return;
    setState(() {
      isDetecting = true;
    });
    final pic = await _controller!.takePicture();

    final data = await pic.readAsBytes();

    image = await decodeImageFromList(data);
    if (!mounted) return;
    if (image != null) {
      setState(() {});

      final results = await decodeImageInIsolate(
        (await image!.toByteData())!.buffer.asUint8List(),
        image!.width,
        image!.height,
      );
      if (!mounted) return;
      setState(() {
        isDetecting = false;
        image = null;
      });
      if (results != null) {
        widget.onResult?.call(results);
        widget.controller?.value = results;
      } else if (!isStop) {
        onCameraView();
      }
    } else {
      setState(() {
        image = null;
        isDetecting = false;
      });
    }
    _controller?.setFocusMode(FocusMode.auto);
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
