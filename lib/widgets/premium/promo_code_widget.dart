import 'dart:developer';

import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class PromoCodeWidget extends StatefulWidget {
  const PromoCodeWidget({super.key});

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          CommonTextField(
            controller: _controller,
            onChanged: (value) {
              if (value.isEmpty || value.endsWith(' ')) return;
              final premiumManager = context.read<PremiumManager>();
              premiumManager.restoreOriginalPrices();
            },
            hint: Strings.promokod,
            contentPadding: const EdgeInsets.only(left: 16, right: 100),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => context.read<PremiumManager>().getPromoCodeValue(_controller.text.trim()),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.colors.accentSub,
                ),
                child: ManagerBuilder<PremiumState, PremiumEffect>(
                  manager: context.read<PremiumManager>(),
                  properties: (state) => [state.isGettingPromoCodeValue],
                  builder: (context, state) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: state.isGettingPromoCodeValue ? 0.0 : 1.0,
                          child: Strings.apply.text(12, 14, 400).c(context.colors.white),
                        ),
                        if (state.isGettingPromoCodeValue) const CupertinoActivityIndicator(color: Colors.white),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
