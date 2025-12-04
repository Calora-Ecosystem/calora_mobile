import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/widgets/svg_buttons_row/svg_button.dart';
import 'package:flutter/material.dart';

class SvgButtonsRow extends StatelessWidget {
  final VoidCallback onGoogleFitTap;
  final VoidCallback onAppleHealthTap;
  final VoidCallback onGarminTap;
  final VoidCallback onSamsungHealthTap;

  final bool isGoogleFitSelected;
  final bool isAppleHealthSelected;
  final bool isGarminSelected;
  final bool isSamsungHealthSelected;

  const SvgButtonsRow({
    super.key,
    required this.onGoogleFitTap,
    required this.onAppleHealthTap,
    required this.onGarminTap,
    required this.onSamsungHealthTap,
    this.isGoogleFitSelected = false,
    this.isAppleHealthSelected = false,
    this.isGarminSelected = false,
    this.isSamsungHealthSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgButton(
            onTap: onAppleHealthTap,
            assetPath: Assets.images.iosHealth.image(),
            isSelected: isAppleHealthSelected,
          ),
          SvgButton(
            onTap: onSamsungHealthTap,
            assetPath: Assets.images.health.image(),
            isSelected: isSamsungHealthSelected,
          ),
          SvgButton(
            onTap: onGarminTap,
            assetPath: Assets.images.garmin.image(),
            isSelected: isGarminSelected,
          ),
          SvgButton(
            onTap: onGoogleFitTap,
            assetPath: Assets.images.googleFit.image(),
            isSelected: isGoogleFitSelected,
          ),
        ],
      ),
    );
  }
}
