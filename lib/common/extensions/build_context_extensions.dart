import 'package:flutter/material.dart';

extension SizeExtension on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get topPadding => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  double get bottomInsets => MediaQuery.of(this).viewInsets.bottom;
}
