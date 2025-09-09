import 'package:flutter/material.dart';

extension GradientTextExtension on Text {
  Widget gradient(Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: this,
    );
  }
}
