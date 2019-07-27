import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'ocr_engine.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(OcrApp());
}

class OcrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter OCR",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter Text Recognizer"),
        ),
        body: CameraPage(),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraPage> {
  CameraController controller;
  bool _isScanBusy = false;
  String _textDetected = "no text detected...";

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.low);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return ListView(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
		GestureDetector(
		onDoubleTap: () async {
                  	controller.startImageStream((CameraImage availableImage) async {
                    	if (_isScanBusy) {
                      		print("1.5 -------- isScanBusy, skipping...");
                      		return;
                    	}

                    	print("1.0 -------- isScanBusy = true");
                    	_isScanBusy = true;

			OcrManager.scanText(availableImage).then( (textVision) {
				setState( () {
					_textDetected = textVision ?? "";
				});

				controller.stopImageStream().then( (smth) { 
					print('2.0 -------- ImageStream stopped, ready to restart.');
					_isScanBusy = false; 
					print('${controller.value}');
				});
						
			});

                  });
              
              	},
		child: Container(
				child: _cameraPreviewWidget(),
				width: 200,
				//width: MediaQuery.of(context).size.width,
			),
		),
            ]
	),
      Text(_textDetected, style: TextStyle(fontSize: 18),),
    ]);
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }
}