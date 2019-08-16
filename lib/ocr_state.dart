import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

class OcrState with ChangeNotifier {
 
  List<CameraDescription> _cameras;
  CameraImage _cameraImage;
  bool _isTextRecognizerBusy = false;
  VisionText _visionText;

  OcrState({List<CameraDescription> cameras}) {
    this._cameras = cameras;
  }

  List<CameraDescription> get cameras => _cameras;

  CameraImage get cameraImage => _cameraImage;

  set cameraImage(CameraImage newValue) {
    _cameraImage = newValue;

    notifyListeners();
  }

  bool get isTextRecognizerBusy => _isTextRecognizerBusy;

  set isTextRecognizerBusy(bool newValue) {
    _isTextRecognizerBusy = newValue;
    notifyListeners();
  }

  VisionText get visionText => _visionText;

  set visionText(VisionText newValue) {
    _visionText = newValue;
    notifyListeners();
  }
}
