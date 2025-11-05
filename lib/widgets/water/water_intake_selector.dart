import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class WaterIntakeSelector extends StatefulWidget {
  final Function(int count) onCountChanged;
  final double bottleCapacity;
  final double targetLiters;
  final double currentIntake;

  const WaterIntakeSelector({
    super.key,
    required this.onCountChanged,
    required this.bottleCapacity,
    required this.targetLiters,
    this.currentIntake = 0.0,
  });

  @override
  State<WaterIntakeSelector> createState() => _WaterIntakeSelectorState();
}

class _WaterIntakeSelectorState extends State<WaterIntakeSelector> {
  int selectedCount = 0;
  int displayCount = 10;

  @override
  void initState() {
    super.initState();
    final minBottles = (widget.targetLiters / widget.bottleCapacity).ceil();
    displayCount = minBottles < 10 ? 10 : minBottles + 2;
  }

  void _updateSelection(int newCount) {
    setState(() {
      selectedCount = newCount;
      if (selectedCount >= displayCount - 2) {
        displayCount += 2;
      }
    });
    widget.onCountChanged(selectedCount);
  }

  bool _isTargetReached() {
    final totalLiters = selectedCount * widget.bottleCapacity;
    return totalLiters >= widget.targetLiters;
  }

  @override
  Widget build(BuildContext context) {
    final targetBottles = (widget.targetLiters / widget.bottleCapacity).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: context.colors.white),
      child: Column(
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Strings.yourWaterIntake.text(20, 24, 600).c(context.colors.textStrong),
              Expanded(
                child: '${widget.targetLiters.toStringAsFixed(1)} L'
                    .text(20, 24, 600)
                    .c(context.colors.textSub)
                    .copyWith(overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          ),
          '${widget.currentIntake.toStringAsFixed(1)} L'.text(20, 24, 600).c(context.colors.textStrong),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(displayCount, (index) {
              final isSelected = index < selectedCount;
              final isNextToSelect = index == selectedCount;
              final isTargetBottle = index == targetBottles - 1;
              final shouldShowDone = isTargetBottle && _isTargetReached();

              return GestureDetector(
                onTap: () {
                  if (isNextToSelect) {
                    _updateSelection(selectedCount + 1);
                  } else if (isSelected) {
                    _updateSelection(index);
                  }
                },
                child: _buildWaterIcon(
                  isSelected: isSelected,
                  showPlusButton: isNextToSelect,
                  isAfterNext: index > selectedCount,
                  showDone: shouldShowDone,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIcon({
    required bool isSelected,
    required bool showPlusButton,
    required bool isAfterNext,
    required bool showDone,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isSelected)
            Assets.icons.blueBotl.svg()
          else if (showPlusButton)
            Assets.icons.botl.svg()
          else if (isAfterNext)
            Assets.icons.softBotl.svg(),
          if (showPlusButton) Positioned(top: -3, right: -3, child: Assets.icons.badge.svg()),
          if (showDone) Positioned(bottom: -1.5, right: 0, child: Assets.icons.circleBadg.svg()),
        ],
      ),
    );
  }
}
