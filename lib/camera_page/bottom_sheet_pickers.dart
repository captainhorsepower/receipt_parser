import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Color _dimmedGray = Color.fromRGBO(190, 190, 190, 0.3);
TextStyle _dimmed = TextStyle(color: _dimmedGray);
TextStyle _active = TextStyle(color: Colors.white);

class MoneyPicker extends StatefulWidget {
  final String text;

  MoneyPicker(this.text, {Key key}) : super(key: key);

  @override
  _MoneyPickerState createState() => _MoneyPickerState();
}

class _MoneyPickerState extends State<MoneyPicker> {
  _MoneyState state = _MoneyState();

  @override
  Widget build(BuildContext context) {
    state.pushUpdate(widget.text);
    state.requireAnimateTo();
    return ChangeNotifierProvider(
      builder: (_) => state,
      child: _MoneyPicker(),
    );
  }
}

class _MoneyState with ChangeNotifier {
  int _grands = 0;
  int _dollars = 0;
  int _cents = 0;

  final int pickerCount = 5;
  int _animatedPickers = 5;

  bool get sholdAnimateTo => _animatedPickers < pickerCount;

  void requireAnimateTo() {
    _animatedPickers = 0;
  }

  void animateOnce() {
    _animatedPickers = min(_animatedPickers + 1, pickerCount);
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

  void pushUpdate(final String text) {
    var money = _findTotalAmountInText(text);
    var newGrands = money ~/ 1000;
    var newDollars = money.floor() % 1000;
    var newCents = ((money - money.truncate()) * 100).truncate();
    if (grands - newGrands + dollars - newDollars + cents - newCents != 0) {
      _grands = newGrands;
      _dollars = newDollars;
      _cents = newCents;
      notifyListeners();
    }
  }

  double _findTotalAmountInText(String text) {
    if (text == null) return 0.0;

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
  final int initialItem;
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final void Function(int index) onSelectedItemChanged;

  final bool looping;
  final double itemExtent;
  final bool useMagnifier;
  final double magnification;
  final Color backgroundColor;

  _GeneralPicker(
      {this.initialItem: 0,
      @required this.itemCount,
      @required this.itemBuilder,
      this.onSelectedItemChanged,
      this.backgroundColor: Colors.transparent,
      this.looping: true,
      this.itemExtent: 60,
      this.useMagnifier: true,
      this.magnification: 1.15}) {
    assert(itemCount != null);
    assert(itemBuilder != null);
  }

  @override
  Widget build(BuildContext context) {
    final scrollController =
        FixedExtentScrollController(initialItem: initialItem);

    final money = Provider.of<_MoneyState>(context);
    if (money.sholdAnimateTo) {
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        print('postframe callback on pickers');
        money.animateOnce();
        scrollController.jumpToItem(initialItem);
        // scrollController.animateToItem(initialItem,
        //     duration: Duration(milliseconds: 3000), curve: Curves.linear);
      });
    }

    return CupertinoPicker(
      scrollController: scrollController,
      looping: looping,
      itemExtent: itemExtent,
      useMagnifier: useMagnifier,
      magnification: magnification,
      backgroundColor: backgroundColor,
      children: List<Widget>.generate(
        itemCount,
        (i) {
          var item = itemBuilder(i);
          return FittedBox(
            fit: BoxFit.contain,
            child: item,
          );
        },
      ),
      onSelectedItemChanged: onSelectedItemChanged,
      diameterRatio: 1.1,
    );
  }
}

class _GrandPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final money = Provider.of<_MoneyState>(context);

    return _GeneralPicker(
      initialItem: money.grands,
      itemCount: 1000,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == money.grands
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: Container(
            child: Text(
              index < 9 ? '$index' : index < 99 ? '$index' : '$index',
              style: index != money.grands || index == 0 ? _dimmed : _active,
            ),
          ),
        );
      },
      onSelectedItemChanged: (int index) {
        money.grands = index;
      },
    );
  }
}

class _ComaPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final money = Provider.of<_MoneyState>(context);
    return _GeneralPicker(
      initialItem: 0,
      itemCount: 1,
      itemBuilder: (_) {
        return Text(
          ' ,',
          style: money.grands > 0 ? _active : _dimmed,
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
    final money = Provider.of<_MoneyState>(context);
    return _GeneralPicker(
      initialItem: money.dollars,
      itemCount: 1000,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == money.dollars
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: money.grands > 0
              ? Text(
                  index < 9 ? '00$index' : index < 99 ? '0$index' : '$index',
                  style: index == money.dollars ? _active : _dimmed,
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
                      style: index == money.dollars ? _active : _dimmed,
                    )
                  ],
                ),
        );
      },
      onSelectedItemChanged: (int index) {
        money.dollars = index;
      },
    );
  }
}

class _DotPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GeneralPicker(
      initialItem: 0,
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
    final money = Provider.of<_MoneyState>(context);

    return _GeneralPicker(
      initialItem: money.cents,
      itemCount: 100,
      itemBuilder: (int index) {
        final EdgeInsets padding = index == money.cents
            ? EdgeInsets.only(top: 4, bottom: 4)
            : EdgeInsets.only(bottom: 6, top: 6);
        return Padding(
          padding: padding,
          child: Text(
            index < 9 ? '0$index' : '$index',
            style: index == money.cents ? _active : _dimmed,
          ),
        );
      },
      onSelectedItemChanged: (int index) {
        money.cents = index;
      },
    );
  }
}

class _MoneyPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moneyStaye = Provider.of<_MoneyState>(context);

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
