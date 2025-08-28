import 'package:flutter/material.dart';

enum DisplayType { error, warning, info, success }

extension DisplayTypeExtensions on DisplayType {
  Color fill(BuildContext context) {
    switch (this) {
      case DisplayType.error:
        return const Color(0xFFFDF0EF);
      case DisplayType.warning:
        return const Color(0xFFFFF5E9);
      case DisplayType.info:
        return const Color(0xFFF5FAFF);
      case DisplayType.success:
        return const Color(0xFFEEFAF3);
    }
  }

  Color stroke(BuildContext context) {
    switch (this) {
      case DisplayType.error:
        return const Color(0xFFFAD1CE);
      case DisplayType.warning:
        return const Color(0xFFFFE0BC);
      case DisplayType.info:
        return const Color(0xFFD9EBFE);
      case DisplayType.success:
        return const Color(0xFFCCF1DA);
    }
  }

  Color shadow(BuildContext context) {
    switch (this) {
      case DisplayType.error:
        return const Color(0x29EE655C);
      case DisplayType.warning:
        return const Color(0x3DFFD5A6);
      case DisplayType.info:
        return const Color(0x1f3f9cfb);
      case DisplayType.success:
        return const Color(0x2954cf85);
    }
  }

  Widget icon(BuildContext context) {
    switch (this) {
      case DisplayType.error:
        return Icon(Icons.info, color: const Color(0xFFEE655C));
      case DisplayType.warning:
        return Icon(Icons.info, color: const Color(0xFFFF9721));
      case DisplayType.info:
        return Icon(Icons.info, color: const Color(0xff3F9CFB));
      case DisplayType.success:
        return Icon(Icons.info, color: const Color(0xff54CF85));
    }
  }
}
