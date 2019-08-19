import 'dart:async';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:camera/camera.dart';
import 'package:progress_indicators/progress_indicators.dart';

import 'package:provider/provider.dart';

import 'package:receipt_parser/camera_page/bottom_action_bar.dart';
import 'package:receipt_parser/camera_page/bottom_sheet_pickers.dart';
import 'package:receipt_parser/camera_page/ocr/ocr_controller.dart';
import 'package:receipt_parser/camera_page/ocr/ocr_state.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(OcrApp());
}

class OcrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter OCR",
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
      ),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: AppBar(
            title: Text('Ready to scan'),
          ),
        ),
        body: ChangeNotifierProvider(
          builder: (context) => OcrState(),
          child: CameraPage(),
        ),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraPage> {
  final _ocrController = OcrController();

  CameraController _controller;

  /// do all necessary OCR work and then return future with VisionText.
  Future<VisionText> _getOcrFuture() {
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
    final maxDelayMillis = 1600;
    return Future.sync(() async {
      while (foo == null) {
        await Future.delayed(Duration(milliseconds: maxDelayMillis));
      }
      return foo;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return Container();

    final ocrState = Provider.of<OcrState>(context);

    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: <Widget>[
        OverflowBox(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: CameraPreview(_controller),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomActionBar.withShutterCallback(() {
            final foo = _getOcrFuture();

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
