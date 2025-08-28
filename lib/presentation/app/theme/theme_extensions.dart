import 'package:calora/common/di/injection.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:flutter/material.dart';

extension ThemeContextExtensions on BuildContext {
  DefaultThemeColors get colors => getIt<DefaultThemeColors>();

  ThemeData get theme => ThemeData(
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: Color(0xFFFFFFFF),
      filled: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8D8D8D),
      ),
    ),
  );
}
