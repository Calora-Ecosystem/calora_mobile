import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

@lazySingleton
class AiApi {
  final Dio _dio;

  AiApi(this._dio);

  Future<Response> analyzeFace(String filePath) async {
    final file = File(filePath);
    final originalBytes = await file.readAsBytes();
    try {
      await file.delete();
    } catch (e) {
      debugPrint('Failed to delete original image at $filePath: $e');
    }

    final croppedBytes = await compute(_cropImageIsolate, originalBytes);

    final FormData formData = FormData.fromMap({
      'File': MultipartFile.fromBytes(
        croppedBytes,
        filename: 'cropped_face.jpg',
      ),
    });
    return _dio.post('face/analyze', data: formData);
  }
}

Uint8List _cropImageIsolate(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception('Could not decode image');
  }

  final size = min(image.width, image.height);
  final croppedImage = img.copyCrop(
    image,
    x: (image.width - size) ~/ 2,
    y: (image.height - size) ~/ 2,
    width: size,
    height: size,
  );

  return img.encodeJpg(croppedImage);
}
