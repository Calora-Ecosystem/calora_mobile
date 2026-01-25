import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String surname;
  final String email;

  final VoidCallback onEdit;

  const ProfileCard({
    super.key,
    required this.surname,
    required this.name,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String initials = name.isNotEmpty ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '';
    final String initialsSurname = surname.isNotEmpty
        ? surname.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '';

    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.strokeSoft, width: 2),
            ),
            child: (initials + initialsSurname).text(20, 24, 600).c(context.colors.accentSub),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    name.text(16, 20, 500).c(context.colors.textStrong),
                    if (context.read<AppManager>().state.isUserPremium) ...[
                      const SizedBox(width: 5),
                      Assets.images.premiumFire.image(height: 24),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                email.text(14, 16, 400).c(context.colors.textSub).copyWith(overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: Assets.icons.editBlack.svg()),
        ],
      ),
    );
  }
}
