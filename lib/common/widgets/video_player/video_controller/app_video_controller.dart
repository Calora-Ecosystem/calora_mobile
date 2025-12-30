import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AppVideoController extends ChangeNotifier {
  late VideoPlayerController controller;
  bool initialized = false;

  Future<void> init(String url) async {
    controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    initialized = true;
    notifyListeners();
  }

  void playPause() {
    controller.value.isPlaying ? controller.pause() : controller.play();
    notifyListeners();
  }

  void disposeController() {
    controller.dispose();
  }
}
