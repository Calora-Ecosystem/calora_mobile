import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

import '../../../../common/gen/assets.gen.dart' show Assets;

class AccountDetailItemBuilder extends StatelessWidget {
  final String title;
  final String? message;
  final String? metric;

  const AccountDetailItemBuilder({
    super.key,
    required this.title,
    this.message,
    this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          title.text(14, 16, 400).c(context.colors.textPrimary),
          message != null
              ? Expanded(
                  child: message
                      .text(14, 16, 400)
                      .c(context.colors.textPrimary),
                )
              : "Kiritish".text(14, 16, 400).c(context.colors.textSub),
          Image.asset(Assets.icons.icArrowRight.path),
        ],
      ),
    );
  }
}
