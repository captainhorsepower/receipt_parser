import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_parser/main.dart';

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

class _CameraAppState extends State<_CameraPage>
    with SingleTickerProviderStateMixin {
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
      _cameraController
          .stopImageStream()
          .then((_) => print('ImageStream stopped'));

      print('Got one Image.');

      foo = _ocrController.recognizeText(availableImage);
    });

    // return ocrFuture with delay <= maxDelayMillis
    final maxDelayMillis = 40;
    return Future.sync(() async {
      while (foo == null) {
        await Future.delayed(Duration(milliseconds: maxDelayMillis));
      }
      return foo;
    });
  }

  Widget _cameraPreview() => AspectRatio(
      aspectRatio: _cameraController.value.aspectRatio,
      child: CameraPreview(_cameraController));

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
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.5, 0.70, 0.82, 0.89, 1.0],
              colors: [
                Colors.black87,
                Colors.black54,
                Colors.black26,
                Colors.black12,
                Colors.transparent
              ],
            ),
            // color: Theme.of(context).primaryColor,
          ),
        ),
      );

  Widget _animatedBottomBar(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;

    return
        // epand bottom sheet (slide up)
        AnimatedBuilder(
      animation: slideUP,
      builder: (context, buildChild) => Container(
        height: slideUP.value,
        child: buildChild,
      ),

      // bottom sheet itself
      child: Container(
        width: maxWidth,
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.bottomCenter,
          //   end: Alignment.topCenter,
          //   stops: [0.8, 0.90, 0.94, 0.97, 1.0],
          //   colors: [
          //     Colors.black,
          //     Colors.black87,
          //     Colors.black54,
          //     Colors.black26,
          //     Colors.black12,
          //   ],
          // ),
          color: Theme.of(context).primaryColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _shutterToPickerTransition(context),
          ],
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
              origin: Offset(0.0, bottomBarHeightExpanded / 2 - 100),
              child: Opacity(
                  opacity: shutterToPickerFlip.value <= pi / 2 ? 1.0 : 0.0,
                  child: flipChild),
            ),

            // shutter bar
            child: Align(
              alignment: Alignment.center,
              child: BottomActionBar.withShutterCallback(() {
                _animationController.forward();

                // get future that returns VisionText,
                // while it's computing I can show animations!
                final foo = _getOcrFuture();

                // // don't forget to update state upon completion
                foo.then((visionText) {
                  Provider.of<OcrState>(context).visionText = visionText;
                });
              }),
            ),
          ),

          // flip part with picker
          AnimatedBuilder(
            animation: shutterToPickerFlip,
            builder: (context, flipChild) => Transform(
              transform: Matrix4.identity()..rotateX(shutterToPickerFlip.value),
              origin: Offset(0.0, bottomBarHeightExpanded / 2),
              child: Opacity(
                  opacity: shutterToPickerFlip.value >= pi / 2 ? 1.0 : 0.0,
                  child: flipChild),
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
          )
        ],
      ),
    );
  }

  Widget _moneyPicker(BuildContext context) {
    return MoneyPicker(
      Provider.of<OcrState>(context).visionText?.text,
    );
  }

  @override
  void initState() {
    _cameraController =
        CameraController(cameras.first, ResolutionPreset.medium);
    _cameraController
        .initialize()
        .then((_) => mounted ? setState(() {}) : () {});

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

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

    slideUP = Tween(begin: bottomSheetHeight, end: moneyPickerHeight)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInCirc),
    ));

    shutterToPickerHeight =
        Tween(begin: bottomBarHeight, end: bottomBarHeightExpanded)
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.4, 0.6, curve: Curves.easeInCirc),
    ));

    shutterToPickerFlip = Tween(begin: 0.0, end: pi).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 0.9, curve: Curves.linear),
    ));

    cameraBlur = Tween(begin: 0.0, end: 10.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    ));

    cameraShadow = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    ));

    return Stack(
      children: <Widget>[
        // camera preview
        OverflowBox(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          child: _cameraController.value.isInitialized
              ? _cameraPreview()
              : _cameraError(context),
        ),

        // "AppBar" with gradient
        Align(
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: 0.5,
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                    Colors.black,
                    Colors.black45,
                    Colors.black26,
                    Colors.transparent
                  ])),
            ),
          ),
        ),

        // blur an opcacity for camera,
        // if used on cameraPreview directly holds an image
        Align(
          alignment: Alignment.center,
          child: _blurShield(),
        ),

        Align(
          alignment: Alignment.bottomCenter,

          // expands bottom sheet
          child: _animatedBottomBar(context),
        ),

        // TODO: remove this
        Align(
            alignment: Alignment(-0.8, 0.0),
            child: GestureDetector(
              onDoubleTap: () => _animationController.forward(),
              child: FloatingActionButton(
                onPressed: () => _animationController.reverse(),
              ),
            ))
      ],
    );
  }
}
