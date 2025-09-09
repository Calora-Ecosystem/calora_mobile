import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/winner/winner.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class WinnerItemBuilder extends StatelessWidget {
  final Winner winner;

  WinnerItemBuilder({super.key, required this.winner});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarWithFlagWidget(initials: winner.getInitials(), flagAsset: Assets.icons.circleFlag.svg()),

      ],
    );
  }
}
