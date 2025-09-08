import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/winner/winner.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
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
        Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: context.colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(child: SizedBox()),
        ),
      ],
    );
  }
}
