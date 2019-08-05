import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'Dart:io';

class AccumulatingStorage {
  
  final _fileName = "local_storage.txt"; 

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<double> readSum() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      return double.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0.0;
    }
  }

  Future<File> _writeSum(double sum) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString('$sum');
  }

  Future<File> addToSum(double addedSum) async {
	return _writeSum(addedSum + (await readSum()) );
  }
}