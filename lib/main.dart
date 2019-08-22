import 'dart:async';
import 'dart:ui' as prefix0;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white, // Color for Android
        statusBarBrightness:
            Brightness.dark // Dark == white status bar -- for IOS.
        ));

    return MaterialApp(
      title: "Flutter OCR",
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        backgroundColor: Colors.black,
        accentColor: Colors.white,
        canvasColor: Colors.black,
        textTheme: TextTheme(
          button: TextStyle(
            fontFamily: '.SF UI Display',
            decoration: TextDecoration.underline,
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
      home: CameraPage(),
    );
  }
}
