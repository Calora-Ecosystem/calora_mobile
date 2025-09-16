import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> captureAndShare(GlobalKey globalKey) async {
  try {
    RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
      paint,
    );

    canvas.drawImage(frame.image, Offset.zero, Paint());

    final finalImage = await recorder.endRecording().toImage(frame.image.width, frame.image.height);

    final finalByteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final finalPngBytes = finalByteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final imagePath = File('${directory.path}/widget_screenshot.png');
    await imagePath.writeAsBytes(finalPngBytes);

    await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out this widget!');
  } catch (e) {
    debugPrint("Screenshot error: $e");
  }
}
