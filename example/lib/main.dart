import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zxing_scanner/zxing_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zxing Scanner Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Zxing Scanner Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScanController controller = ScanController();

  void _startScan() {
    controller.start();
  }

  void alert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void showResult(List<Result>? results) {
    if (results?.isEmpty ?? true) {
      alert('未识别到二维码');
    } else {
      alert(
        '共识别出${results!.length}个二维码\n${results.map(((e) => e.text)).join('\n')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ScanView(
        autoStart: false,
        controller: controller,
        onResult: showResult,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: GestureDetector(
                  onTap: () async {
                    Feedback.forTap(context);
                    controller.stop();
                    final XFile? image = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final results =
                          await scanImage(await image.readAsBytes());
                      showResult(results);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.image,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: _startScan,
                  icon: const Icon(Icons.camera),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
