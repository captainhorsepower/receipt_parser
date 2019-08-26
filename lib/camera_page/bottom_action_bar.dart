import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:receipt_parser/camera_page/bottom_action_bar_state.dart';

import 'ocr/ocr_state.dart';

class _FlashlightToggle extends StatelessWidget {
  final double _size;
  _FlashlightToggle(this._size);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LampSwitchState>(context);

    return MaterialButton(
      child: Icon(
        state.isOn ? Icons.flash_on : Icons.flash_off,
        color: CupertinoColors.white.withOpacity(state.isOn ? 1.0 : 0.7),
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
    final ocrState = Provider.of<OcrState>(context);
    final isInProgress = ocrState.isRecognitionInProgress;

    return MaterialButton(
      child: isInProgress
          ? CircularProgressIndicator()
          : Icon(
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
        color: CupertinoColors.white.withOpacity(0.7),
      ),
      onPressed: () {
        final text = Provider.of<OcrState>(context).visionText?.text ?? 'Nothing recognized yet.';
        showDialog(
          context: context,
          builder: (context) {
            return GestureDetector(
              onForcePressPeak: (forcePressDetails) {
                HapticFeedback.vibrate();
              },
              onTap: () {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop();
              },
              child: Dialog(
                insetAnimationDuration: Duration(seconds: 3),
                elevation: 50.0,
                backgroundColor: Colors.blue,
                child: Container(
                  height: 500,
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ListView(
                      children: <Widget>[
                        Text('$text'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final _flashIconSize = 35.0;
  final _shutterIconSize = 75.0;
  final _imageIconSize = 35.0;

  final VoidCallback _shutterCallback;

  BottomActionBar.withShutterCallback(this._shutterCallback);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (context) => LampSwitchState(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          _LastImageButton(_imageIconSize),
          _ShutterButton(_shutterIconSize, _shutterCallback),
          _FlashlightToggle(_flashIconSize),
        ],
      ),
    );
  }
}
