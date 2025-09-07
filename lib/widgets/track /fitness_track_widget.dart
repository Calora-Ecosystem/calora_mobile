import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FitnessTrackWidget extends StatelessWidget {
  const FitnessTrackWidget({
    super.key,
    required this.onClickForward,
    required this.onClickBackward,
    required this.onClickPause,
    required this.onClickMoreVert,
    this.selectedDate,
  });

  final Function() onClickForward;
  final Function() onClickBackward;
  final Function() onClickPause;
  final Function() onClickMoreVert;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: context.colors.accentSub,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onClickBackward,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Assets.icons.icBackward.svg(),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      "Bugun".text(14, 16, 400).c(context.colors.textWhite),
                      SizedBox(height: 4),
                      "7- sentabr"
                          .text(14, 16, 400)
                          .c(context.colors.textWhite),
                    ],
                  ),
                  InkWell(
                    onTap: onClickForward,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Assets.icons.icForward.svg(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.white,
                  borderRadius: BorderRadius.all(
                     Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: onClickPause,
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: Assets.icons.icPause.svg(),
                          ),
                        ),
                        InkWell(
                          onTap: onClickMoreVert,
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: Assets.icons.icMoreVert.svg(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 100,
                      child: Center(child: Text("Insert Progressbar")),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Assets.icons.icStopwatch.svg(),
                            SizedBox(height: 4),
                            '0 S'
                                .text(16, 20, 500)
                                .c(context.colors.textStrong),
                            SizedBox(height: 2),
                            Strings.onTime
                                .text(14, 20, 400)
                                .c(context.colors.textSub),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Assets.icons.icDistance.svg(),
                            SizedBox(height: 4),
                            '0'
                                .text(16, 20, 500)
                                .c(context.colors.textStrong),
                            SizedBox(height: 2),
                            Strings.distanceInKm
                                .text(14, 20, 400)
                                .c(context.colors.textSub),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Assets.icons.icCalorie.svg(),
                            SizedBox(height: 4),
                            '0'
                                .text(16, 20, 500)
                                .c(context.colors.textStrong),
                            SizedBox(height: 2),
                            Strings.calorie
                                .text(14, 20, 400)
                                .c(context.colors.textSub),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
