import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_parser/main.dart';
import 'package:taptic_feedback/taptic_feedback.dart';

import 'bottom_action_bar.dart';
import 'bottom_sheet_pickers.dart';
import 'ocr/ocr_controller.dart';
import 'ocr/ocr_state.dart';

class CameraPage extends StatelessWidget {
  final appBarHeight = 40.0;
  final title = 'Ready to scan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        builder: (context) => OcrState(),
        child: _CameraPage(),
      ),
    );
  }
}

class _CameraPage extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<_CameraPage> with SingleTickerProviderStateMixin {
  final _ocrController = OcrController();

  CameraController _cameraController;
  AnimationController _animationController;

  /// bottom bar slide up
  Animation<double> slideUP;
  Animation<double> shutterToPickerHeight;

  /// switch bottom bar actions to money picker
  Animation<double> shutterToPickerFlip;

  Animation<double> cameraBlur;
  Animation<double> cameraShadow;

  Animation<double> removeButtonsFromScreen;
  Animation<double> buttonsFadeIn;

  final bottomBarHeight = 80.0;
  final bottomBarHeightExpanded = 200.0;

  final bottomSheetHeight = 80.0;
  final moneyPickerHeight = 300.0;

  /// do all necessary OCR work and then return future with VisionText.
  Future<VisionText> _getOcrFuture() {
    if (!_cameraController.value.isInitialized) {
      print('Camera Controller is not initialized!');
      return null;
    }

    // just a security check to prevent unwanted errors. Should never happen.
    if (_cameraController.value.isStreamingImages) {
      print('ImageStream has already been started, skipping...');
      return null;
    }

    // helper var, will use to temproraily store ocrFuture
    var foo;

    bool canUseImageStream = true;
    print('Starting ImageStream...');

    _cameraController.startImageStream((CameraImage availableImage) {
      if (!canUseImageStream) return;

      canUseImageStream = false;
      _cameraController.stopImageStream().then((_) => print('ImageStream stopped'));

      print('Got one Image.');

      foo = _ocrController.recognizeText(availableImage);
    });

    // return ocrFuture with delay <= maxDelayMillis
    final maxDelayMillis = 50;
    return Future.sync(() async {
      while (foo == null) {
        await Future.delayed(Duration(milliseconds: maxDelayMillis));
      }
      return foo;
    });
  }

  Widget _cameraPreview() => AspectRatio(
      aspectRatio: _cameraController.value.aspectRatio, child: CameraPreview(_cameraController));

  Widget _cameraError(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;
    return Container(
      color: Theme.of(context).disabledColor,
      width: maxWidth,
      height: maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Text("Can't open the camera", textScaleFactor: 2.0),
          Text(r'¯\_(ツ)_/¯', textScaleFactor: 3.0),
        ],
      ),
    );
  }

  Widget _blurShield() => AnimatedBuilder(
        animation: cameraBlur,
        builder: (_, builderChild) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: cameraBlur.value,
              sigmaY: cameraBlur.value,
            ),
            child: Opacity(
              opacity: cameraShadow.value,
              child: builderChild,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          // color: Theme.of(context).primaryColor,
        ),
      );

  Widget _appBarGradient() => Opacity(
        opacity: 0.4,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0.0, 0.0),
              colors: [Colors.black, Colors.transparent],
            ),
          ),
        ),
      );

  Widget _animatedBottomBar(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        color: Theme.of(context).primaryColor.withOpacity(0.55),
      ),

      // epand bottom sheet (slide up)
      child: AnimatedBuilder(
        animation: slideUP,
        builder: (context, buildChild) => Container(
          height: slideUP.value,
          child: buildChild,
        ),

        // bottom sheet itself
        child: Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Center(
            child: _shutterToPickerTransition(context),
          ),
        ),
      ),
    );
  }

  Widget _shutterToPickerTransition(BuildContext context) {
    return // height transition from shutter to picker
        AnimatedBuilder(
      animation: shutterToPickerHeight,
      builder: (context, sizeTransitionChild) => Container(
        height: shutterToPickerHeight.value,
        child: sizeTransitionChild,
      ),

      // shutter button and picker overlayed on stack
      child: Stack(
        children: [
          // flip part with shutter bar
          AnimatedBuilder(
            animation: shutterToPickerFlip,
            builder: (context, flipChild) => Transform(
              transform: Matrix4.identity()..rotateX(shutterToPickerFlip.value),
              origin: Offset(0.0, bottomBarHeightExpanded / 2 - 103),
              child: Opacity(
                  opacity: shutterToPickerFlip.value <= pi / 2 ? 1.0 : 0.0, child: flipChild),
            ),

            // shutter bar
            child: Align(
              alignment: Alignment.center,
              child: BottomActionBar.withShutterCallback(() {
                final ocrState = Provider.of<OcrState>(context);
                ocrState.isRecognitionInProgress = true;

                // get future that returns VisionText,
                // while it's computing I can show animations!
                final foo = _getOcrFuture();

                // don't forget to update state upon completion
                foo.then((visionText) {
                  _animationController.forward();
                  ocrState.visionText = visionText;

                  ocrState.isRecognitionInProgress = false;
                  ocrState.total == OcrState.errFlag
                      ? TapticFeedback.tripleLight()
                      : TapticFeedback.light();
                });
              }),
            ),
          ),

          // flip part with picker
          AnimatedBuilder(
            animation: shutterToPickerFlip,
            builder: (context, flipChild) => Transform(
              transform: Matrix4.identity()..rotateX(shutterToPickerFlip.value),
              origin: Offset(0.0, bottomBarHeightExpanded / 2 - 15),
              child: Opacity(
                  opacity: shutterToPickerFlip.value >= pi / 2 ? 1.0 : 0.0, child: flipChild),
            ),

            // money picker
            child: Align(
              alignment: Alignment.center,
              child: Transform(
                transform: Matrix4.identity()..rotateX(pi),
                origin: Offset(0.0, bottomBarHeightExpanded / 2),
                child: _moneyPicker(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyPicker(BuildContext context) {
    return MoneyPicker(
      Provider.of<OcrState>(context).total,
    );
  }

  Widget _bottomBarButtons(BuildContext context) => AnimatedBuilder(
        animation: removeButtonsFromScreen,
        builder: (context, movingButtons) => Transform(
          transform: Matrix4.identity()..rotateX(removeButtonsFromScreen.value),
          origin: Offset(0.0, 100.0),
          child: Opacity(opacity: buttonsFadeIn.value, child: movingButtons),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // save button
              Container(
                width: 100,
                child: CupertinoButton(
                  child: Text('Save', style: Theme.of(context).textTheme.button),
                  onPressed: () {},
                ),
              ),

              // cancel button
              Container(
                width: 100,
                child: CupertinoButton(
                  child: Text(
                    'Discard',
                    style: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () {
                    _animationController.reverse();
                  },
                ),
              )
            ],
          ),
        ),
      );

  @override
  void initState() {
    _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
    _cameraController.initialize().then((_) => mounted ? setState(() {}) : () {});

    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));

    super.initState();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController?.dispose();
    _ocrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;

    // ##############################
    // ###### INIT ANIMATIONS #######
    // ##############################

    slideUP = Tween(begin: bottomSheetHeight, end: moneyPickerHeight).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInCirc),
    ));

    shutterToPickerHeight =
        Tween(begin: bottomBarHeight, end: bottomBarHeightExpanded).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.4, 0.6, curve: Curves.easeInCirc),
    ));

    shutterToPickerFlip = Tween(begin: 0.0, end: pi).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 0.9, curve: Curves.linear),
    ));

    cameraBlur = Tween(begin: 0.0, end: 6.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    ));

    cameraShadow = Tween(begin: 0.0, end: 0.3).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    ));

    removeButtonsFromScreen = Tween(begin: pi, end: 0.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.3, curve: Curves.linear),
    ));

    buttonsFadeIn = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animationController, curve: Interval(0.5, 1.0, curve: Curves.ease)));

    return Stack(
      children: <Widget>[
        // camera preview
        OverflowBox(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          child: _cameraController.value.isInitialized ? _cameraPreview() : _cameraError(context),
        ),

        // "AppBar" with gradient
        Align(
          alignment: Alignment.topCenter,
          child: _appBarGradient(),
        ),

        // blur an opcacity for camera,
        // if used on cameraPreview directly holds an image
        Align(
          alignment: Alignment.center,
          child: _blurShield(),
        ),

        // bar with shutter button that
        // transfroms into pickers
        Align(
          alignment: Alignment.bottomCenter,
          child: _animatedBottomBar(context),
        ),

        // Discard and Save buttons
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBarButtons(context),
        ),
      ],
    );
  }
}
