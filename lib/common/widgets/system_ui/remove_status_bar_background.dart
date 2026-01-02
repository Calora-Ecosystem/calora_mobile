import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemoveStatusBarBackground extends StatelessWidget {
  final Widget child;

  const RemoveStatusBarBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final systemUiOverlayStyle = SystemUiOverlayStyle(
      systemStatusBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(value: systemUiOverlayStyle, child: child);
  }
}
