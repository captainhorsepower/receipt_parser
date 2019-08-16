import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:camera/camera.dart';

import 'dart:async';

import 'package:lamp/lamp.dart';
import 'package:provider/provider.dart';
import 'package:receipt_parser/ocr_controller.dart';

import 'ocr_engine.dart';
import 'file_storage.dart';
import 'ocr_state.dart';

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
      theme: ThemeData.dark().copyWith(primaryColor: Colors.black),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            title: Text('Ocr Receipts'),
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
  CameraController controller;

  String _persistentText = "file is not opened";
  int _dollars = 0;
  int _cents = 0;
  int _grands = 0;

  final _ocrController = OcrController();
  final storage = AccumulatingStorage();
  final lamp = LampController();

  void _doOcrStuff(final OcrState ocrState) {
    if (controller.value.isStreamingImages) {
      print('ImageStream has already been started, skipping...');
      return;
    }

    bool canUseImageStream = true;
    print('Starting ImageStream...');

    controller.startImageStream((CameraImage availableImage) {
      if (!canUseImageStream) return;

      canUseImageStream = false;
      controller.stopImageStream().then((_) => print('ImageStream stopped'));

      print('Got one Image.');

      ocrState.cameraImage = availableImage;

      _ocrController.recognizeText(availableImage).then((visionText) {
        ocrState.visionText = visionText;
        _showPickers(ocrState);
      });
    });
  }

  _findMaxSum(String text) {
    RegExp exp = new RegExp(
        r"[1-9]\d{0,2}(,|-|\s|\.)*((\d|U|D){3}(,|-|\s|\.)*)*((,|-|\.)(\d|U|D){2})\n");

    Iterable<RegExpMatch> matches = exp.allMatches(text);

    if (matches == null || matches.isEmpty) {
      return _grands * 1000 + _dollars + _cents / 100;
    }

    matches.forEach((match) => print('------- match ------ ${match.group(0)}'));

    return matches
        .map((match) => match
            .group(0)
            .replaceAll(new RegExp(r'(,|\s|\.|-)'), "")
            .replaceAll(new RegExp(r'(U|D|\d){2}$'),
                match.group(5).replaceAll(new RegExp(r'(,|\s|\.|-)'), '.'))
            .replaceAll(new RegExp(r'(U|D)'), "0")
            .trim())
        //.join("; ");
        .map((str) => double.parse(str))
        .reduce((curr, next) => curr > next ? curr : next);
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _ocrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return Container();

    return Stack(
      children: <Widget>[
        OverflowBox(
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: () {
            print('width ${MediaQuery.of(context).size.width}');
            print('height ${MediaQuery.of(context).size.height}');
            return MediaQuery.of(context).size.width;
          }(),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 80,
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    child: Icon(
                      !lamp.isOn ? Icons.flash_off : Icons.flash_on,
                      color: Colors.yellow,
                      size: 55,
                    ),
                    onPressed: () => lamp.toggle(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    child: Icon(
                      Icons.camera,
                      size: 55,
                    ),
                    onPressed: () =>
                        _doOcrStuff(Provider.of<OcrState>(context)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    child: false
                        ? Icon(
                            Icons.photo,
                            size: 55,
                          )
                        : Text('sucks'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _showPickers(OcrState ocrState) {
    showModalBottomSheet(
        //shape: CircleBorder(),
        //elevation: 40.0,
        context: context,
        builder: (BuildContext context) {
          String text = ocrState.visionText.text;
          return Text(text);
        });
  }

  Widget multipicker() {
    return Container(
      height: 270,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200.0,
            width: 300,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 87,
                  child: CupertinoPicker(
                      looping: true,
                      scrollController: new FixedExtentScrollController(
                        initialItem: _grands,
                      ),
                      itemExtent: 26.0,
                      useMagnifier: true,
                      magnification: 2.0,
                      backgroundColor: Colors.white,
                      onSelectedItemChanged: (int index) {
                        setState(() {
                          _grands = index;
                        });
                      },
                      children: new List<Widget>.generate(1000, (int index) {
                        return new Center(
                          child: FittedBox(
                            child: new Text('${index}'),
                            fit: BoxFit.cover,
                          ),
                        );
                      })),
                ),
                // Container(
                //   width: 25,
                //   child: CupertinoPicker(
                //       itemExtent: 26.0,
                //       useMagnifier: true,
                //       magnification: 2.0,
                //       backgroundColor: Colors.white,
                //       onSelectedItemChanged: (int index) {
                //         setState(() {
                //           _dollars = index;
                //         });
                //       },
                //       children: new List<Widget>.generate(1, (int index) {
                //         return new Center(
                //           child: FittedBox(
                //             child: new Text('${(_grands > 0) ? ',' : ''}'),
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       })),
                // ),
                // Container(
                //   width: 87,
                //   child: CupertinoPicker(
                //       looping: true,
                //       scrollController: new FixedExtentScrollController(
                //         initialItem: _dollars,
                //       ),
                //       itemExtent: 26.0,
                //       useMagnifier: true,
                //       magnification: 2.0,
                //       backgroundColor: Colors.white,
                //       onSelectedItemChanged: (int index) {
                //         setState(() {
                //           _dollars = index;
                //           print('dollars selected');
                //         });
                //       },
                //       children: new List<Widget>.generate(1000, (int index) {
                //         return new Center(
                //           child: FittedBox(
                //             child: new Text('${index}'),
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       })),
                // ),
                // Container(
                //   width: 25,
                //   child: CupertinoPicker(
                //       itemExtent: 26.0,
                //       useMagnifier: true,
                //       magnification: 2.0,
                //       backgroundColor: Colors.white,
                //       onSelectedItemChanged: (int index) {
                //         setState(() {
                //           _dollars = index;
                //           print('dollars selected');
                //         });
                //       },
                //       children: new List<Widget>.generate(1, (int index) {
                //         return new Center(
                //           child: FittedBox(
                //             child: new Text('.'),
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       })),
                // ),
                // Container(
                //   width: 70,
                //   child: CupertinoPicker(
                //       looping: true,
                //       scrollController: new FixedExtentScrollController(
                //         initialItem: _cents,
                //       ),
                //       itemExtent: 26.0,
                //       useMagnifier: true,
                //       magnification: 2.0,
                //       backgroundColor: Colors.white,
                //       onSelectedItemChanged: (int index) {
                //         setState(() {
                //           _cents = index;
                //         });
                //       },
                //       children: new List<Widget>.generate(100, (int index) {
                //         return new Center(
                //           child: FittedBox(
                //             child: new Text(
                //                 '${index >= 10 ? index : '0' + index.toString()}'),
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       })),
                // ),
              ],
            ),
          ),
          Text('accumulated sum: $_persistentText'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                child: Text('read'),
                onPressed: () async {
                  final persistedSum = await storage.readSum();
                  setState(() => {_persistentText = '$persistedSum'});
                },
              ),
              CupertinoButton(
                child: Text('store'),
                onPressed: () async {
                  await storage
                      .addToSum(_grands * 1000 + _dollars + _cents / 100);
                  final persistedSum = await storage.readSum();
                  setState(() => {_persistentText = '$persistedSum'});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LampController {
  bool isOn = false;

  turnOn({intensity: 1.0}) {
    Lamp.turnOn(intensity: intensity);
    isOn = true;
  }

  turnOff() {
    Lamp.turnOff();
    isOn = false;
  }

  toggle() {
    isOn ? turnOff() : turnOn();
    isOn != isOn;
  }
}
