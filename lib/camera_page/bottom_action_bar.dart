
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:receipt_parser/camera_page/ocr/ocr_state.dart';
import 'package:receipt_parser/camera_page/bottom_action_bar_state.dart';

class _FlashlightToggle extends StatelessWidget {
  final double _size;
  _FlashlightToggle(this._size);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LampSwitchState>(context);

    return MaterialButton(
      child: Icon(
        state.isOn ? Icons.flash_on : Icons.flash_off,
        color: CupertinoColors.white,
        size: _size,
      ),
      onPressed: () => state.isOn = !state.isOn,
      splashColor: Colors.transparent,
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final double _size;
  final VoidCallback _callback;
  _ShutterButton(this._size, this._callback);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      child: Icon(
        CupertinoIcons.circle_filled,
        size: _size,
        color: CupertinoColors.white,
      ),
      onPressed: _callback,
      splashColor: Colors.transparent,
    );
  }
}

class _LastImageButton extends StatelessWidget {
  final double _size;

  _LastImageButton(this._size);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      child: Icon(
        Icons.history,
        size: _size,
      ),
      onPressed: () {},
      splashColor: Colors.transparent,
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final _bottomBarHeight = 80.0;

  final _flashIconSize = 35.0;
  final _shutterIconSize = 75.0;
  final _imageIconSize = 35.0;

  final VoidCallback _shutterCallback;

  BottomActionBar.withShutterCallback(this._shutterCallback);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: _bottomBarHeight,
      color: Theme.of(context).primaryColor,
      child: ChangeNotifierProvider(
        builder: (context) => LampSwitchState(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _LastImageButton(_imageIconSize),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: _ShutterButton(_shutterIconSize, _shutterCallback),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _FlashlightToggle(_flashIconSize),
            ),
          ],
        ),
      ),
    );
  }
}
