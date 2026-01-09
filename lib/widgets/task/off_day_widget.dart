import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class OffDayWidget extends StatelessWidget {
  const OffDayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.backgroundElevation,
            ),
            child: Assets.icons.dayOffIcon.svg(),
          ),
          SizedBox(height: 8),
          Strings.youCanRelaxTuday
              .text(20, 24, 600)
              .c(context.colors.neutral900Primary),
          SizedBox(height: 8),
          Strings.yourBodyAndMusclessNeedToRest
              .text(16, 20, 400)
              .c(context.colors.textSub)
              .copyWith(maxLines: 2, textAlign: TextAlign.center),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              context.router.pop();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: context.colors.backgroundElevation,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Strings.close
                  .text(16, 20, 500)
                  .c(context.colors.textStrong)
                  .copyWith(textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
