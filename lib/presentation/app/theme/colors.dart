import 'dart:ui';

import 'package:injectable/injectable.dart';

@lazySingleton
class DefaultThemeColors {
  final strokeAccent = Color(0xFF46A758);
  final textStrong = Color(0xFF202020);
  final textWhite = Color(0xFFFCFCFC);
  final textSub = Color(0XFF8D8D8D);
  final neutralSecondary = Color(0xFF68778D);
  final accentSub = Color(0xFF46A758);
  final backgroundBase = Color(0xFFFFFFFF);
  final strokeSoft = Color(0xFFF0F0F0);
  final accentSoft = Color(0xFF94CE9A);
  final accentWhite = Color(0xFFFBFEFB);
  final commonBackground = Color(0xFFF2F3F7);
  final modalBackground = Color(0xFFD1D3D9);
  final iconSub = Color(0xFF646464);
}
