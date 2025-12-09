import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ActionsPage extends StatelessWidget {
  final VoidCallback? onTapDelete;
  final VoidCallback? onTapShare;

  const ActionsPage({super.key, this.onTapDelete, this.onTapShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(color: context.colors.strokeSub, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Strings.actions.text(20, 24, 700).c(context.colors.textStrong),
            dense: true,
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Assets.icons.delete.svg(),
            title: Strings.dataCleaning.text(14, 18, 400).c(context.colors.textPrimary),
            onTap: () {
              Navigator.pop(context);
              onTapDelete?.call();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Assets.icons.share.svg(),
            title: Strings.share.text(14, 18, 400).c(context.colors.textPrimary),
            onTap: () {
              Navigator.pop(context);
              onTapShare?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
