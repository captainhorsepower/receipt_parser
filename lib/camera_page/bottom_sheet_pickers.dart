import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Color _dimmedGray = Color.fromRGBO(190, 190, 190, 0.3);
TextStyle _dimmed = TextStyle(color: _dimmedGray);
TextStyle _active = TextStyle(color: Colors.white);

class MoneyPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => _MoneyState("100.50"),
      child: _MoneyPicker(),
    );
  }
}

class _MoneyState with ChangeNotifier {
  int _grands = 0;
  int _dollars = 0;
  int _cents = 0;

  _MoneyState(final String text) {
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
    final leadingSymbols = '[1-9]\\d{0,2}';
    final separator = '(\\.|,| {1}) ?';
    final innerSymbols = '(\\d|U|D){3}';
    final cents = '(\\d|U|D){2}';
    final notDigit = '[^\\d]';

    RegExp exp = RegExp(
        "(^|$notDigit)$leadingSymbols($separator$innerSymbols){0,2}$separator$cents(\$|$notDigit)");

    List<RegExpMatch> matches = exp.allMatches(text).toList();

    if (matches.isEmpty) {
      return 0.0;
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

class _GeneralPicker extends StatelessWidget {
  final int _initialItem;
  final int _itemCount;
  final Widget Function(int index) _itemBuilder;
  final void Function(int index) _onSelectedItemChanged;
  final FixedExtentScrollController _scrollController;

  final bool _looping;
  final double _itemExtent;
  final bool _useMagnifier;
  final double _magnification;
  final Color _backgroundColor;

  _GeneralPicker.private(
      this._initialItem,
      this._itemCount,
      this._itemBuilder,
      this._onSelectedItemChanged,
      this._scrollController,
      this._backgroundColor,
      this._looping,
      this._itemExtent,
      this._useMagnifier,
      this._magnification);

  static of({
    @required int initalItem,
    @required int itemCount,
    @required Widget Function(int index) itemBuilder,
    @required void Function(int index) onSelectedItemChanged,
    Color backgroundColor: Colors.transparent,
    bool looping: true,
    double itemExtent: 60,
    bool useMagnifier: true,
    double magnification: 1.15,
  }) {
    return _GeneralPicker.private(
        initalItem,
        itemCount,
        itemBuilder,
        onSelectedItemChanged,
        FixedExtentScrollController(initialItem: initalItem),
        backgroundColor,
        looping,
        itemExtent,
        useMagnifier,
        magnification);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: _scrollController,
      looping: _looping,
      itemExtent: _itemExtent,
      useMagnifier: _useMagnifier,
      magnification: _magnification,
      backgroundColor: _backgroundColor,
      children: List<Widget>.generate(
        _itemCount,
        (i) {
          var item = _itemBuilder(i);
          return FittedBox(
            fit: BoxFit.contain,
            child: item,
          );
        },
      ),
      onSelectedItemChanged: _onSelectedItemChanged,
      diameterRatio: 1.1,
    );
  }
}

class _GrandPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _moneyState = Provider.of<_MoneyState>(context);

    return _GeneralPicker.of(
      initalItem: _moneyState.grands,
      itemCount: 1000,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == _moneyState.grands
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: Container(
            child: Text(
              index < 9 ? '$index' : index < 99 ? '$index' : '$index',
              style:
                  index != _moneyState.grands || index == 0 ? _dimmed : _active,
            ),
          ),
        );
      },
      onSelectedItemChanged: (int index) {
        _moneyState.grands = index;
      },
    );
  }
}

class _ComaPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _moneyState = Provider.of<_MoneyState>(context);
    return _GeneralPicker.of(
      initalItem: 0,
      itemCount: 1,
      itemBuilder: (_) {
        return Text(
          ' ,',
          style: _moneyState.grands > 0 ? _active : _dimmed,
        );
      },
      onSelectedItemChanged: null,
      looping: false,
    );
  }
}

class _DollarPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _moneyState = Provider.of<_MoneyState>(context);
    return _GeneralPicker.of(
      initalItem: _moneyState.dollars,
      itemCount: 1000,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == _moneyState.dollars
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: _moneyState.grands > 0
              ? Text(
                  index < 9 ? '00$index' : index < 99 ? '0$index' : '$index',
                  style: index == _moneyState.dollars ? _active : _dimmed,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      index < 9 ? '00' : index < 99 ? '0' : '',
                      style: _dimmed,
                    ),
                    Text(
                      '$index',
                      style: index == _moneyState.dollars ? _active : _dimmed,
                    )
                  ],
                ),
        );
      },
      onSelectedItemChanged: (int index) {
        _moneyState.dollars = index;
      },
    );
  }
}

class _DotPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GeneralPicker.of(
      initalItem: 0,
      itemCount: 1,
      itemBuilder: (_) => Text(
        '.',
        textAlign: TextAlign.center,
      ),
      onSelectedItemChanged: null,
      looping: false,
    );
  }
}

class _CentPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _moneyState = Provider.of<_MoneyState>(context);

    return _GeneralPicker.of(
      initalItem: _moneyState.cents,
      itemCount: 100,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == _moneyState.cents
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: Text(
            index < 9 ? '0$index' : '$index',
            style: index == _moneyState.cents ? _active : _dimmed,
          ),
        );
      },
      onSelectedItemChanged: (int index) {
        _moneyState.cents = index;
      },
    );
  }
}

class _MoneyPicker extends StatefulWidget {
  double _total = 0.0;
  double get total => _total;

  @override
  _MoneyPickerState createState() => _MoneyPickerState();
}

class _MoneyPickerState extends State<_MoneyPicker> {
  @override
  Widget build(BuildContext context) {
    final moneyStaye = Provider.of<_MoneyState>(context);

    widget._total =
        moneyStaye.grands * 1000 + moneyStaye.dollars + moneyStaye.cents / 100;

    return Container(
      width: 320,
      height: 180,
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  flex: 60,
                  child: Container(child: _GrandPicker()),
                ),
                Flexible(
                  flex: 10,
                  child: _ComaPicker(),
                ),
                Flexible(
                  flex: 60,
                  child: Container(child: _DollarPicker()),
                ),
                Flexible(
                  flex: 10,
                  fit: FlexFit.tight,
                  child: _DotPicker(),
                ),
                Flexible(
                  flex: 60,
                  child: Container(child: _CentPicker()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
