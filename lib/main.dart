import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:camera/camera.dart';

import 'dart:async';

import 'package:lamp/lamp.dart';

import 'ocr_engine.dart';
import 'file_storage.dart'; 


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
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
        	middle: Text('Cupertino Accountant'),
        ),        
	child: CameraPage(),
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
  bool _isScanBusy = false;
  String _textDetected = "no text detected...";
  String _persistentText = "file is not opened";
  String _filePath = null;
  int _dollars = 0;
  int _cents = 0; 
  int _grands = 0; 

  final storage = AccumulatingStorage();
  final lamp = LampController(); 

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return 
	Stack (children: <Widget>[
       		GestureDetector(
			onDoubleTap: () async {
                  		controller.startImageStream((CameraImage availableImage) async {
	                    		if (_isScanBusy) {
        	              			print("1.5 -------- isScanBusy, skipping...");
	                	      		return;
        	            		}
	
        	            		print("1.0 -------- isScanBusy = true");
	        	            	_isScanBusy = true;

					OcrManager.scanText(availableImage).then( (textVision) {
						setState( () {
							_textDetected = textVision ?? "";

							double maxSum = _findMaxSum(_textDetected);
							print('max sum == $maxSum');

							_cents = (100 * (maxSum - maxSum.floor())).floor();
							_dollars = maxSum.floor() % 1000;
							_grands = (maxSum.floor() / 1000).floor();
						});

						controller.stopImageStream().then( (smth) { 
							print('2.0 -------- ImageStream stopped, ready to restart.');
							_isScanBusy = false; 
							//print('${controller.value}');
						});

						_showPickers();	
					});
	                  	});

				
              		},
			child: Container(
				child: FittedBox (
					//fit: (MediaQuery.of(context).size.height / MediaQuery.of(context).size.width > controller.value.aspectRatio) ? BoxFit.fitHeight : BoxFit.fitWidth,
					fit: BoxFit.cover,
					child: _cameraPreviewWidget(),
				),
				width: MediaQuery.of(context).size.width,
				height: MediaQuery.of(context).size.height,
				color: Colors.black,
			),
		),
		Align(
  			alignment: Alignment(-1.1, -0.80),
			child: CupertinoButton(
  				child: Icon(
					!lamp.isOn ? Icons.flash_off : Icons.flash_on,
					color: Colors.yellow,
					size: 50,
  				),
				onPressed: () {
					lamp.toggle();
					setState( () => {} );
				}
			),
		),
	],);
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Container(
		width: 20, 
		child: Align(
			alignment: Alignment(0.0, 0.0),
			child: AspectRatio(
        			aspectRatio: controller.value.aspectRatio,
        			child: CameraPreview(controller),
      			),
		),
	 );
    }
  }

  _findMaxSum(String text) {

    RegExp exp = new RegExp(r"[1-9]\d{0,2}(,|-|\s|\.)*((\d|U|D){3}(,|-|\s|\.)*)*((,|-|\.)(\d|U|D){2})\n");

    Iterable<RegExpMatch> matches = exp.allMatches(text);
     
    if (matches == null || matches.isEmpty) {
      return _grands * 1000 + _dollars + _cents / 100;
    }

    matches.forEach( (match) => print ('------- match ------ ${match.group(0)}') ); 
    
    return matches
        .map( (match) => match.group(0)
				.replaceAll(new RegExp(r'(,|\s|\.|-)'), "")
				.replaceAll(new RegExp(r'(U|D|\d){2}$'), match.group(5).replaceAll(new RegExp(r'(,|\s|\.|-)'), '.') )
				.replaceAll(new RegExp(r'(U|D)'), "0")
				.trim() 
	) 
        //.join("; ");
        .map( (str) => double.parse(str) )
        .reduce( (curr, next) => curr > next ? curr : next );
  }

 
  _showPickers() {
                      showModalBottomSheet(
		          //shape: CircleBorder(), 
			  //elevation: 40.0,
                          context: context,
                          builder: (BuildContext context) {
                            return multipicker(); 
                          });
                    }

	Widget multipicker() {
		return Container( height: 270, color: Colors.white, child: Column( children: [
			Container(
                              height: 200.0,
			      width: 300,
                              color: Colors.white,
                              child: Row(
                              //  crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
				  Container(
				    width: 87,
                                    child: CupertinoPicker(
					looping: true,
                                        scrollController:
                                            new FixedExtentScrollController(
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
                                        children: new List<Widget>.generate(1000,
                                            (int index) {
                                          return new Center(
                                            child: FittedBox(
							child: new Text('${index}'),
							fit: BoxFit.cover,
						   ),
                                          );
                                        })),
                                  ),
				  Container(
				    width: 25,
                                    child: CupertinoPicker(
                                        itemExtent: 26.0,
					useMagnifier: true,
					magnification: 2.0,
                                        backgroundColor: Colors.white,
                                        onSelectedItemChanged: (int index) {
                                          setState(() {
                                            _dollars = index;
                                          });
                                        },
                                        children: new List<Widget>.generate(1,
                                            (int index) {
                                          return new Center(
                                            child: FittedBox(
							child: new Text('${(_grands > 0) ? ',' : ''}'),
							fit: BoxFit.cover,	
						),
                                          );
                                        })),
                                  ),
                                  Container(
				    width: 87,
                                    child: CupertinoPicker(
					looping: true,
                                        scrollController:
                                            new FixedExtentScrollController(
                                          initialItem: _dollars,
                                        ),
                                        itemExtent: 26.0,
					useMagnifier: true,
					magnification: 2.0,
                                        backgroundColor: Colors.white,
                                        onSelectedItemChanged: (int index) {
                                          setState(() {
                                            _dollars = index;
					    print('dollars selected');
                                          });
                                        },
                                        children: new List<Widget>.generate(1000,
                                            (int index) {
                                          return new Center(
                                            child: FittedBox(
							child: new Text('${index}'),
							fit: BoxFit.cover,	
						),
                                          );
                                        })),
                                  ),
				  Container(
				    width: 25,
                                    child: CupertinoPicker(
				
                                        itemExtent: 26.0,
					useMagnifier: true,
					magnification: 2.0,
                                        backgroundColor: Colors.white,
                                        onSelectedItemChanged: (int index) {
                                          setState(() {
                                            _dollars = index;
					    print('dollars selected');
                                          });
                                        },
                                        children: new List<Widget>.generate(1,
                                            (int index) {
                                          return new Center(
                                            child: FittedBox(
							child: new Text('.'),
							fit: BoxFit.cover,	
						),
                                          );
                                        })),
                                  ),
                                  Container(
				    width: 70,
                                    child: CupertinoPicker(
					looping: true,
                                        scrollController:
                                            new FixedExtentScrollController(
                                          initialItem: _cents,
                                        ),
                                        itemExtent: 26.0,
					useMagnifier: true,
					magnification: 2.0,
                                        backgroundColor: Colors.white,
                                        onSelectedItemChanged: (int index) {
                                          setState(() {
                                            _cents = index;
                                          });
                                        },
                                        children: new List<Widget>.generate(100,
                                            (int index) {
                                          return new Center(
                                            child: FittedBox (
							child: new Text('${index >= 10 ? index : '0' + index.toString() }'),
							fit: BoxFit.cover,
						   ),
                                          );
                                        })),
                                  ),
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
							setState( () => {
								_persistentText = '$persistedSum'
							});
						},
			    		),
					CupertinoButton(
						child: Text('store'),
						onPressed: () async {
							await storage.addToSum(_grands * 1000 + _dollars + _cents / 100);
							final persistedSum = await storage.readSum();
							setState( () => {
								_persistentText = '$persistedSum'
							});
						},
			    		),
				],
			    ),
			  
			],),);
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