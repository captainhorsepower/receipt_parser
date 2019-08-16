import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

class OcrState with ChangeNotifier {
 
  CameraImage _cameraImage;
  VisionText _visionText;

  CameraImage get cameraImage => _cameraImage;

  set cameraImage(CameraImage newValue) {
    _cameraImage = newValue;
    notifyListeners();
  }

  VisionText get visionText => _visionText;

  set visionText(VisionText newValue) {
    _visionText = newValue;
    notifyListeners();
  }
}
