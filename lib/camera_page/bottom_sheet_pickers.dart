import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MultiPickerState with ChangeNotifier {
  int _grands = 0;
  int _dollars = 0;
  int _cents = 0;

  MultiPickerState(final String text) {
    final money = _findTotalAmountInText(text);
    _grands = money ~/ 1000;
    _dollars = money.floor() % 1000;
    _cents = ((money - money.truncate()) * 100).truncate();
  }

  int get grands => _grands;
  int get dollars => _dollars;
  int get cents => _cents;

  set grands(int newValue) {
    _grands = newValue;
    notifyListeners();
  }

  set dollars(int newValue) {
    _dollars = newValue;
    notifyListeners();
  }

  set cents(int newValue) {
    _cents = newValue;
    notifyListeners();
  }

  double _findTotalAmountInText(String text) {
    debugPrint('got text : $text');

    final leadingSymbols = '[1-9]\\d{0,2}';
    final separator = '(\\.|,| {1}) ?';
    final innerSymbols = '(\\d|U|D){3}';
    final cents = '(\\d|U|D){2}';
    final notDigit = '[^\\d]';

    RegExp exp = RegExp(
        "(^|$notDigit)$leadingSymbols($separator$innerSymbols){0,2}$separator$cents(\$|$notDigit)");

    print(exp.toString());
    List<RegExpMatch> matches = exp.allMatches(text).toList();

    if (matches.isEmpty) {
      return -1.0;
    }

    matches.removeWhere((m) {
      return m.group(0)[0].startsWith(RegExp("(\\(|-|:)"));
    });

    return matches
        .map((match) {
          var tmp = match.group(0).replaceAll(RegExp(r'(U|D)'), '0');
          tmp = tmp.replaceAll(RegExp(notDigit), "");
          tmp = tmp.substring(0, tmp.length - 2) +
              '.' +
              tmp.substring(tmp.length - 2);
          return tmp;
        })
        .map((str) => double.parse(str))
        .reduce((curr, next) => curr > next ? curr : next);
  }
}

class _GeneralPicker extends StatefulWidget {
  int _initialItem;
  int _itemCount;
  Widget Function(int index) _itemBuilder;
  void Function(int index) _onSelectedItemChanged;

  bool _looping;
  double _itemExtent;
  bool _useMagnifier;
  double _magnification;
  Color _backgroundColor;

  _GeneralPicker({
    @required int initalItem,
    @required int itemCount,
    @required Widget Function(int index) itemBuilder,
    @required void Function(int index) onSelectedItemChanged,
    Color backgroundColor: Colors.green,
    bool looping: true,
    double itemExtent: 26,
    bool useMagnifier: true,
    double magnification: 2.0,
  }) {
    _initialItem = initalItem;
    _itemCount = itemCount;
    _itemBuilder = itemBuilder;
    _onSelectedItemChanged = onSelectedItemChanged;

    _backgroundColor = backgroundColor;
    _looping = looping;
    _itemExtent = itemExtent;
    _useMagnifier = useMagnifier;
    _magnification = magnification;
  }

  @override
  __GeneralPickerState createState() => __GeneralPickerState();
}

class __GeneralPickerState extends State<_GeneralPicker> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: new FixedExtentScrollController(
        initialItem: widget._initialItem,
      ),
      looping: widget._looping,
      itemExtent: widget._itemExtent,
      useMagnifier: widget._useMagnifier,
      magnification: widget._magnification,
      backgroundColor: widget._backgroundColor,
      children: List<Widget>.generate(
        widget._itemCount,
        widget._itemBuilder,
      ),
      onSelectedItemChanged: widget._onSelectedItemChanged,
    );
  }
}

class _GrandPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moneyState = Provider.of<MultiPickerState>(context);

    return _GeneralPicker(
      initalItem: moneyState.grands,
      itemCount: 1000,
      itemBuilder: (int index) {
        return Text('$index');
      },
      onSelectedItemChanged: (int index) {
        moneyState.grands = index;
      },
    );
  }
}

class _DollarPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moneyState = Provider.of<MultiPickerState>(context);

    return _GeneralPicker(
      initalItem: moneyState.dollars,
      itemCount: 1000,
      itemBuilder: (int index) {
        return Text(',$index');
      },
      onSelectedItemChanged: (int index) {
        moneyState.dollars = index;
      },
    );
  }
}

class _CentPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moneyState = Provider.of<MultiPickerState>(context);

    return _GeneralPicker(
      initalItem: moneyState.cents,
      itemCount: 100,
      itemBuilder: (int index) {
        return Text('.$index');
      },
      onSelectedItemChanged: (int index) {
        moneyState.cents = index;
      },
    );
  }
}

class MoneyMultiPicker extends StatefulWidget {
  double _total = -1.0;
  double get total => _total;

  @override
  _MoneyMultiPickerState createState() => _MoneyMultiPickerState();
}

class _MoneyMultiPickerState extends State<MoneyMultiPicker> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(height: 160, width: width, child: _GrandPicker()),
        Container(height: 160, width: width, child: _DollarPicker()),
        Container(height: 160, width: width, child: _CentPicker()),
      ],
    );
  }
}
