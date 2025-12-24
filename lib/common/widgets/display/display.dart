import 'package:flutter/material.dart';
import 'package:calora/common/widgets/display/display_message.dart';

abstract class Display {
  void setOnDisplayListener(void Function(DisplayMessage message) onDisplay);

  void error(String description, [String? title]);

  void warning(String description, [String? title]);

  void info({required String description, String? title, VoidCallback? onTap, Duration? duration,});

  void success(String description, [String? title]);
}
