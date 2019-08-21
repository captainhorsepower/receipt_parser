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

class _CameraAppState extends State<_CameraPage> {
  final _ocrController = OcrController();

  CameraController _controller;

  /// do all necessary OCR work and then return future with VisionText.
  Future<VisionText> _getOcrFuture() {
    if (!_controller.value.isInitialized) {
      print('Camera Controller is not initialized!');
      return null;
    }

    // just a security check to prevent unwanted errors. Should never happen.
    if (_controller.value.isStreamingImages) {
      print('ImageStream has already been started, skipping...');
      return null;
    }

    // helper var, will use to temproraily store ocrFuture
    var foo;

    bool canUseImageStream = true;
    print('Starting ImageStream...');

    _controller.startImageStream((CameraImage availableImage) {
      if (!canUseImageStream) return;

      canUseImageStream = false;
      _controller.stopImageStream().then((_) => print('ImageStream stopped'));

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
      aspectRatio: _controller.value.aspectRatio,
      child: CameraPreview(_controller));

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

  @override
  void initState() {
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    _controller.initialize().then((_) => mounted ? setState(() {}) : () {});
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = Provider.of<OcrState>(context);

    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: <Widget>[
        OverflowBox(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          child: _controller.value.isInitialized
              ? _cameraPreview()
              : _cameraError(context),
        ),

        // TODO: add opacity and blur (BackdropFilter) animations 
        Align(
          alignment: Alignment.center,
          child: Opacity(
            opacity: 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: BottomActionBar.withShutterCallback(() {
            
            // get future that returns VisionText, 
            // while it's computing I can show animations!
            final foo = _getOcrFuture();

            // don't forget to update state upon completion
            foo.then((visionText) {
              ocrState.visionText = visionText;
            });

            // should be always true, just attempt to prevent some silly bugs
            if (foo != null) {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  final _dimmedGray = Color.fromRGBO(190, 190, 190, 1.0);
                  final cupertinoButtonsStyle =
                      TextStyle(fontSize: 18, color: _dimmedGray);

                  return Container(
                    height: 350,
                    child: FutureBuilder(
                      future: foo,
                      builder: (context, snapshot) {
                        var picker = MoneyPicker();

                        return Column(
                          children: <Widget>[
                            Flexible(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15.0, bottom: 5),
                                  child: Container(
                                    height: 100,
                                    child: snapshot.connectionState ==
                                            ConnectionState.done
                                        ? Text(
                                            'Adjust receipt total:',
                                            style: TextStyle(
                                                fontSize: 26,
                                                color: _dimmedGray),
                                          )
                                        : FadingText(
                                            'Adjust receipt total:',
                                            style: TextStyle(
                                                fontSize: 26,
                                                color: _dimmedGray),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 12,
                              child: Container(
                                height: 200,
                                // child: false
                                child: snapshot.connectionState ==
                                        ConnectionState.done
                                    ? ChangeNotifierProvider(
                                        builder: (_) =>
                                            MoneyState(snapshot.data?.text),
                                        child: picker,
                                      )
                                    : JumpingDotsProgressIndicator(
                                        fontSize: 60,
                                        color: _dimmedGray,
                                        numberOfDots: 7,
                                        dotSpacing: 2.0,
                                        milliseconds: 200,
                                      ),
                              ),
                            ),
                            Flexible(
                              flex: 3,
                              child: Container(
                                height: 50,
                                child: snapshot.connectionState ==
                                        ConnectionState.done
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          CupertinoButton(
                                            child: Text('cancel',
                                                style: cupertinoButtonsStyle),
                                            onPressed: () => Navigator.pop(
                                              context,
                                            ),
                                          ),
                                          CupertinoButton(
                                            child: Text('done',
                                                style: cupertinoButtonsStyle),
                                            onPressed: () => Navigator.pop(
                                              context,
                                              picker.total,
                                            ),
                                          ),
                                        ],
                                      )
                                    : CupertinoButton(
                                        child: Text('cancel',
                                            style: cupertinoButtonsStyle),
                                        onPressed: () => Navigator.pop(
                                          context,
                                        ),
                                      ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  );
                },
              ).then((val) {
                if (val != null)
                  showBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container();
                      });
              });
            }
          }),
        ),
      ],
    );
  }
}
