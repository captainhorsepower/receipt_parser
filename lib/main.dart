import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReceiptPareserHomePage(),
    );
  }
}

class ReceiptPareserHomePage extends StatefulWidget {
  @override
  _ReceiptPareserHomePageState createState() => _ReceiptPareserHomePageState();
}

class _ReceiptPareserHomePageState extends State<ReceiptPareserHomePage> {
  File _image;
  VisionText _visionText;

  Future _pickAnImage(src) async {
    print('picking image...');

    final imageFile = await ImagePicker.pickImage(
      source: src,
    );

    print('picked image: $imageFile.toString()');

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();

    print('started text recognition;');

    final VisionText recognizedText =
        await textRecognizer.processImage(visionImage);

    print('text recoginzed.');

    if (mounted) {
      setState(() {
        _image = imageFile;
        _visionText = recognizedText;
      });
    }
  }

  _findMaxSum() {
    String text = _visionText.blocks
          .map( (block) => block.text )
          .join('\n');

    RegExp exp = new RegExp(r"(\d{1,4},*)+\.\d{2}");
    Iterable<RegExpMatch> matches = exp.allMatches(text);
     
    if (matches == null || matches.isEmpty) {
      return "TOTAL SUM NOT FOUND";
    }

    return matches
        .map( (match) => match.group(0).replaceAll(",", "") )
        .map( (str) => double.parse(str) )
        .reduce( (curr, next) => curr > next ? curr : next)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receipt Parser Snapshot"),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            _image == null
                ? Text('No image selected.')
                : Column(
                    children: <Widget>[
                      GestureDetector(
                        child: Image.file(_image), 
                        onDoubleTap: () => _pickAnImage(ImageSource.gallery),
                      ),
                      Text("MAX SUM? :"),
                      Text(
                        _findMaxSum()
                      ),
                    ],
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAnImage(ImageSource.camera),
        tooltip: 'Pick an Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
