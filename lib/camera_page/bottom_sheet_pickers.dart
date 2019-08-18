import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MultiPickerState with ChangeNotifier {
  double _money;

  double get money => _money;

  set money(double newValue) {
    _money = money;
    notifyListeners();
  }
}

class _GrandPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      looping: true,
      scrollController: new FixedExtentScrollController(
        initialItem: 0,
      ),
      itemExtent: 26.0,
      useMagnifier: true,
      magnification: 2.0,
      backgroundColor: Colors.white,
      onSelectedItemChanged: (int index) {},
      children: List<Widget>.generate(1000, (i) {
        return new Center(
          child: FittedBox(
            child: new Text('${i}'),
            fit: BoxFit.cover,
          ),
        );
      }),
    );
  }
}

class _DollarPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      looping: true,
      scrollController: new FixedExtentScrollController(
        initialItem: 0,
      ),
      itemExtent: 26.0,
      useMagnifier: true,
      magnification: 2.0,
      backgroundColor: Colors.white,
      onSelectedItemChanged: (int index) {},
      children: List<Widget>.generate(1000, (i) {
        return new Center(
          child: FittedBox(
            child: new Text('${i}'),
            fit: BoxFit.cover,
          ),
        );
      }),
    );
  }
}

class _CentPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      looping: true,
      scrollController: new FixedExtentScrollController(
        initialItem: 0,
      ),
      itemExtent: 26.0,
      useMagnifier: true,
      magnification: 2.0,
      backgroundColor: Colors.white,
      onSelectedItemChanged: (int index) {},
      children: List<Widget>.generate(100, (i) {
        return new Center(
          child: FittedBox(
            child: new Text('.${i}'),
            fit: BoxFit.cover,
          ),
        );
      }),
    );
  }
}

class MoneyMultiPicker extends StatefulWidget {

  MoneyMultiPicker(String this._text);
  
  final _text;

  double _total = -1.0;
  double get total => _total;

  @override
  _MoneyMultiPickerState createState() => _MoneyMultiPickerState();
}

class _MoneyMultiPickerState extends State<MoneyMultiPicker> {
  
  double _findTotalAmountInText(String text) {
    RegExp exp = new RegExp(
        r"[1-9]\d{0,2}(,|-|\s|\.)*((\d|U|D){3}(,|-|\s|\.)*)*((,|-|\.)(\d|U|D){2})\n");

    Iterable<RegExpMatch> matches = exp.allMatches(text);

    if (matches.isEmpty) {
      return -1.0;
    }

    return matches
        .map((match) => match
            .group(0)
            .replaceAll(new RegExp(r'(,|\s|\.|-)'), "")
            .replaceAll(new RegExp(r'(U|D|\d){2}$'),
                match.group(5).replaceAll(new RegExp(r'(,|\s|\.|-)'), '.'))
            .replaceAll(new RegExp(r'(U|D)'), "0")
            .trim())
        .map((str) => double.parse(str))
        .reduce((curr, next) => curr > next ? curr : next);
  }

  @override
  Widget build(BuildContext context) {
    widget._total = _findTotalAmountInText(widget._text);

    return ChangeNotifierProvider(
      builder: (_) => MultiPickerState(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
