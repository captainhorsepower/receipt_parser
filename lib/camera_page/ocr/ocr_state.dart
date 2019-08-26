import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

class OcrState with ChangeNotifier {
  static final errFlag = -1.0;

  VisionText _visionText;
  double _total;
  bool _isRecognitionInProgress = false;

  get isRecognitionInProgress => _isRecognitionInProgress;

  set isRecognitionInProgress(final bool newValue) {
    _isRecognitionInProgress = newValue;
    notifyListeners();
  }

  VisionText get visionText => _visionText;

  set visionText(VisionText newValue) {
    _visionText = newValue;
    _total = _findTotalAmountInText(_visionText.text);
    notifyListeners();
  }

  double get total => _total;

  set total(double newValue) {
    if (total == _total) return;
    _total = newValue;
    notifyListeners();
  }

  double _findTotalAmountInText(String text) {
    if (text == null) return errFlag;

    final leadingSymbols = '[1-9]\\d{0,2}';
    final separator = '(\\.|,| {1}) ?';
    final innerSymbols = '(\\d|U|D){3}';
    final cents = '(\\d|U|D){2}';
    final notDigit = '[^\\d]';

    RegExp exp = RegExp(
      "(^|$notDigit)$leadingSymbols($separator$innerSymbols){0,2}$separator$cents(\$|$notDigit)",
    );

    List<RegExpMatch> matches = exp.allMatches(text).toList();

    if (matches.isEmpty) {
      return errFlag;
    }

    matches.removeWhere((m) => m.group(0)[0].startsWith(RegExp("(\\(|-|:)")));

    final tmp = matches.map((match) {
      var tmp = match.group(0).replaceAll(RegExp(r'(U|D)'), '0');
      tmp = tmp.replaceAll(RegExp(notDigit), "");
      tmp = tmp.substring(0, tmp.length - 2) + '.' + tmp.substring(tmp.length - 2);
      return tmp;
    }).map((str) => double.parse(str));

    return tmp.isEmpty ? errFlag : tmp.reduce((curr, next) => curr > next ? curr : next);
  }
}
