import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ocr_state.dart';

class OcrController {
  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.textRecognizer();

  void recognizeText(
      OcrState state, CameraImage cameraImage) {
    if (state.isTextRecognizerBusy) return null;

    FirebaseVisionImage visionImage = _toFirebaseVisionImage(cameraImage);
    _textRecognizer.processImage(visionImage).then((VisionText visionText) {
      state.visionText = visionText;
    });
  }

  void dispose() {
    _textRecognizer.close();
  }

  FirebaseVisionImage _toFirebaseVisionImage(CameraImage availableImage) {
    return FirebaseVisionImage.fromBytes(
      _getBytes(availableImage),
      _buildMetaData(availableImage),
    );
  }

  FirebaseVisionImageMetadata _buildMetaData(CameraImage image) {
    return FirebaseVisionImageMetadata(
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: ImageRotation.rotation90,
      planeData: image.planes.map((Plane plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList(),
    );
  }

  Uint8List _getBytes(CameraImage image) {
    final planes = image.planes;
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }
}
