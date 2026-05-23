import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FileValidationHelper {
  Future<bool> isFileUnder2MB(XFile file) async {
    int sizeInBytes;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      sizeInBytes = bytes.length;
    } else {
      sizeInBytes = await File(file.path).length();
    }

    final sizeInMb = sizeInBytes / (1024 * 1024);

    print('File path: ${file.path}');
    print('File size bytes: $sizeInBytes');
    print('File size MB: $sizeInMb');

    return sizeInBytes <= 2 * 1024 * 1024;
  }
}