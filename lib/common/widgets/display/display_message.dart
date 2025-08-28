import 'package:flutter/material.dart';

import 'display_type.dart';

class DisplayMessage {
  final DisplayType type;
  final String description;
  final String? title;
  final VoidCallback? onTap;
  final Duration? duration;

  DisplayMessage(this.type, this.description, [this.title, this.onTap, this.duration] );
}
