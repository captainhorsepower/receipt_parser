import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

class OcrState with ChangeNotifier {
 
  VisionText _visionText;
  double _total;

  VisionText get visionText => _visionText;

  set visionText(VisionText newValue) {
    _visionText = newValue;
    notifyListeners();
  }

  double get total => _total;

  set total(double newValue) {
    if (total == _total) return;
    _total = newValue;
    notifyListeners();
  }
}
