import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Banner on the Steps tab that leads into step groups (create / join / group
/// ranking). Uses the app's mint gradient so it reads as a highlighted CTA
/// among the white step cards.
class GroupBanner extends StatelessWidget {
  const GroupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.router.push(GroupsRoute()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            center: const Alignment(1.4, -0.8),
            radius: 1.6,
            colors: [colors.honeydew, colors.mintGreen],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                color: colors.textWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  'group_banner_title'
                      .tr()
                      .text(15, 20, 700)
                      .c(colors.textWhite),
                  const SizedBox(height: 2),
                  'group_banner_desc'
                      .tr()
                      .text(12, 16, 500)
                      .c(colors.textWhite.withValues(alpha: 0.9)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textWhite),
          ],
        ),
      ),
    );
  }
}
