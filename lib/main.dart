import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:camera/camera.dart';

import 'package:provider/provider.dart';

import 'package:receipt_parser/camera_page/ocr/ocr_state.dart';

import 'camera_page/camera_page.dart';

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
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        backgroundColor: Colors.black,
        accentColor: Colors.white,
        canvasColor: Colors.black,
      ),
      home: CameraPage(),
    );
  }
}
