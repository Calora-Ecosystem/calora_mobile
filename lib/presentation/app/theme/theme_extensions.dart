import 'package:calora/common/di/injection.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:flutter/material.dart';

extension ThemeContextExtensions on BuildContext {
  DefaultThemeColors get colors => getIt<DefaultThemeColors>();

  ThemeData get theme => ThemeData(
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF46A758),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFFFFFFFF),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8D8D8D),
      ),
    ),
  );
}
