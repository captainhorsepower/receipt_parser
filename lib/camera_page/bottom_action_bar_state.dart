import 'package:flutter/foundation.dart';
import 'package:lamp/lamp.dart';

class LampSwitchState with ChangeNotifier {
  bool _isOn;

  LampSwitchState() {
    _isOn = false;
    Lamp.turnOff();
  }

  bool get isOn => _isOn;

  set isOn(bool newValue) {
    _isOn = newValue;
    
    _isOn ? Lamp.turnOn() : Lamp.turnOff();

    notifyListeners();
  }
}