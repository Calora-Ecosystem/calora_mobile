import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import 'display.dart';
import 'display_message.dart';
import 'display_type.dart';

@Singleton(as: Display)
class DisplayImpl extends Display {
  void Function(DisplayMessage message)? _onDisplay;

  void _display(DisplayType type, String description, [String? title, VoidCallback? onTap, Duration? duration]) =>
      _onDisplay?.call(
        DisplayMessage(
          type,
          description,
          title,
          onTap,
          duration,
        ),
      );

  @override
  void error(String description, [String? title]) => _display(
        DisplayType.error,
        description,
        title,
      );

  @override
  void warning(String description, [String? title]) => _display(
        DisplayType.warning,
        description,
        title,
      );

  @override
  void info({required String description, String? title, VoidCallback? onTap, Duration? duration}) =>
      _display(
        DisplayType.info,
        description,
        title,
        onTap,
        duration,
      );

  @override
  void success(String description, [String? title]) => _display(
        DisplayType.success,
        description,
        title,
      );

  @override
  void setOnDisplayListener(void Function(DisplayMessage message) onDisplay) {
    _onDisplay = onDisplay;
  }
}
