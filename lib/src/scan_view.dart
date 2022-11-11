import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:zxing_lib/zxing.dart';

import 'controller.dart';
import 'foundation/scan_image.dart';

class ScanView extends StatefulWidget {
  const ScanView({
    super.key,
    this.child,
    this.autoStart = true,
    this.flashMode = FlashMode.off,
    this.onError,
    this.onResult,
    this.controller,
  });

  final Widget? child;
  final bool autoStart;
  final FlashMode flashMode;
  final Function(dynamic)? onError;
  final Function(List<Result>)? onResult;
  final ScanController? controller;

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> implements ScanState {
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
        _controller = CameraController(
          _cameras![0],
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
          Future.delayed(Duration.zero).then((value) => onCameraView());
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
    XFile pic = await _controller!.takePicture();

    Uint8List data = await pic.readAsBytes();

    image = await decodeImageFromList(data);
    if (!mounted) return;
    if (image != null) {
      setState(() {});

      var results = await decodeImageInIsolate(
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
