import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

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
    String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "";
    String initialsSurname = surname.isNotEmpty
        ? surname.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
              children: [
                name.text(16, 20, 500).c(context.colors.textStrong),
                const SizedBox(height: 8),
                email.text(14, 16, 400).c(context.colors.textSub),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: Assets.icons.editBlack.svg()),
        ],
      ),
    );
  }
}
