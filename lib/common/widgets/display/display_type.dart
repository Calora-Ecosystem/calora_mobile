import 'package:calora/common/gen/assets.gen.dart';
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
        return Assets.icons.alertError.svg(height: 28, width: 28);
      case DisplayType.warning:
        return Assets.icons.alertWarning.svg(height: 28, width: 28);
      case DisplayType.info:
        return Assets.icons.alertInfo.svg(height: 28, width: 28);
      case DisplayType.success:
        return Assets.icons.alertSuccess.svg(height: 28, width: 28);
    }
  }
}
