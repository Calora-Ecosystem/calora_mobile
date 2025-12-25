import 'package:calora/widgets/podium/podium_bar_widget.dart';
import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  const PodiumWidget({
    super.key,
    required this.firstPosition,
    required this.secondPosition,
    required this.thirdPosition,
    this.height = 70,
    this.width = 100,
    this.horizontalSpacing = 3,
    this.firstRankingText = '1',
    this.secondRankingText = '2',
    this.thirdRankingText = '3',
  });

  ///Defines the widget for the first position podium in the center.
  final Widget firstPosition;

  ///Defines the widget for the second position podium to the left.
  final Widget secondPosition;

  ///Defines the widget for the third position podium to the right
  final Widget thirdPosition;

  ///Horizontal spacing between each of the podium bars
  final double horizontalSpacing;

  ///Defines the height of the first position podium bar (max height), consequently defining the heights of the other two bars,
  ///as a fraction of the defined height.
  final double height;

  ///Defines the width of a podium bar
  final double width;

  ///Defines the first position ranking text inside the podium bar.
  ///NEEDS LEADING AND TRAILING SPACES TO ENSURE PROPER ALIGNMENT.
  final String firstRankingText;

  ///Defines the second position ranking text inside the podium bar.
  ///NEEDS LEADING AND TRAILING SPACES TO ENSURE PROPER ALIGNMENT.
  ///
  final String secondRankingText;

  ///Defines the third position ranking text inside the podium bar.
  ///NEEDS LEADING AND TRAILING SPACES TO ENSURE PROPER ALIGNMENT.
  final String thirdRankingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PodiumBarWidget(
          title: secondPosition,
          width: width,
          rankingText: secondRankingText,
          height: height / 1.5,
        ),
        SizedBox(width: horizontalSpacing),
        PodiumBarWidget(
          title: firstPosition,
          width: width,
          rankingText: firstRankingText,
          height: height,
        ),
        SizedBox(width: horizontalSpacing),
        PodiumBarWidget(
          title: thirdPosition,
          width: width,
          rankingText: thirdRankingText,
          height: height / 2.2,
        ),
      ],
    );
  }
}
