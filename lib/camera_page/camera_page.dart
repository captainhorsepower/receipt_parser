import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          title: Text('$title'),
        ),
      ),
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
  Animation<double> slideUp;

  /// switch bottom bar actions to money picker
  Animation<double> flip;
  Animation<double> cameraBlur;
  Animation<double> cameraDimming;

  final bottomBarHeight = 100.0;
  final raisedBottomBarHeight = 400.0;

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
                  opacity: cameraDimming.value,
                  child: builderChild,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
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
    final ocrState = Provider.of<OcrState>(context);

    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;


    // ##############################
    // ###### INIT ANIMATIONS #######
    // ##############################

    slideUp = Tween(begin: bottomBarHeight, end: raisedBottomBarHeight)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceIn,
    ));

    flip = Tween(begin: 0.0, end: pi).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceIn,
    ));

    cameraBlur = Tween(begin: 0.0, end: 10.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    ));
    
    cameraDimming = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(
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

        // blur an opcacity for camera, 
        // if used on cameraPreview directly holds an image
        Align(
          alignment: Alignment.center,
          child: _blurShield(),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: BottomActionBar.withShutterCallback(() {
            _animationController.forward();

            // get future that returns VisionText,
            // while it's computing I can show animations!
            // final foo = _getOcrFuture();

            // don't forget to update state upon completion
            // foo.then((visionText) {
            //   ocrState.visionText = visionText;
            // });
          }),
        ),


        // TODO: remove this
        Align(
            alignment: Alignment(-0.8, 0.95),
            child: FloatingActionButton(
              onPressed: () => _animationController.reverse(),
            ))
      ],
    );
  }
}
