import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onTabNotification;
  final ProfileRequest? profile;

  const HomeAppBar({super.key, required this.isScrolled, required this.profile, required this.onTabNotification});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name;
    String initials = (name != null && name.isNotEmpty)
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 45, 20, 16),
      decoration: BoxDecoration(color: isScrolled ? context.colors.white : Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.strokeSoft, width: 2),
            ),
            child: initials.text(20, 24, 600).c(context.colors.accentSub).copyWith(textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Strings.hello.text(12, 14, 500), (profile?.name ?? '').text(16, 20, 500)],
          ),
          const Spacer(),
          InkWell(onTap: onTabNotification, child: Assets.icons.notification.svg()),
        ],
      ),
    );
  }
}
