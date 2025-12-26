import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class WaterIntakeSelector extends StatefulWidget {
  final Function(int count) onCountChanged;
  final double bottleCapacity;
  final double targetLiters;
  final double currentIntake;
  final DateTime date;
  final bool loading;

  const WaterIntakeSelector({
    super.key,
    required this.onCountChanged,
    required this.bottleCapacity,
    required this.targetLiters,
    this.currentIntake = 0.0,
    required this.date,
    required this.loading,
  });

  @override
  State<WaterIntakeSelector> createState() => _WaterIntakeSelectorState();
}

class _WaterIntakeSelectorState extends State<WaterIntakeSelector> {
  int selectedCount = 0;
  int displayCount = 10;

  bool get _isToday {
    final now = DateTime.now();
    return now.year == widget.date.year && now.month == widget.date.month && now.day == widget.date.day;
  }

  @override
  void initState() {
    super.initState();

    final minBottles = ((widget.targetLiters / 1000) / widget.bottleCapacity).ceil();
    displayCount = minBottles < 10 ? 10 : minBottles + 2;

    selectedCount = (widget.currentIntake / widget.bottleCapacity).floor();
  }

  @override
  void didUpdateWidget(covariant WaterIntakeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.date != widget.date || oldWidget.currentIntake != widget.currentIntake) {
      selectedCount = (widget.currentIntake / widget.bottleCapacity).floor();
    }
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
    return totalLiters >= widget.targetLiters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final targetBottles = ((widget.targetLiters / 1000) / widget.bottleCapacity).ceil();
    final itemCount = _isToday ? displayCount : selectedCount;
    return ShimmerWrapper(
      loading: widget.loading,
      shimmerChild: ShimmerChild(
        height: 184,
        radius: 20,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.colors.white,
        ),
        child: Column(
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.yourWaterIntake.text(20, 24, 600).c(context.colors.textStrong),
                Expanded(
                  child: '${widget.targetLiters / 1000} L'
                      .text(20, 24, 600)
                      .c(context.colors.textSub)
                      .copyWith(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                ),
              ],
            ),
            '${widget.currentIntake} L'.text(20, 24, 600).c(context.colors.textStrong),

            /// 🟦 Bottle’lar
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(itemCount, (index) {
                final isSelected = index < selectedCount;
                final isNextToSelect = _isToday && index == selectedCount;
                final isAfterNext = _isToday && index > selectedCount;

                final isTargetBottle = index == targetBottles - 1;
                final shouldShowDone = _isToday && isTargetBottle && _isTargetReached();

                return GestureDetector(
                  onTap: !_isToday
                      ? null
                      : () {
                          if (isNextToSelect) {
                            _updateSelection(selectedCount + 1);
                          } else if (isSelected) {
                            _updateSelection(index);
                          }
                        },
                  child: _buildWaterIcon(
                    isSelected: isSelected,
                    showPlusButton: isNextToSelect,
                    isAfterNext: isAfterNext,
                    showDone: shouldShowDone,
                  ),
                );
              }),
            ),
          ],
        ),
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

          if (showPlusButton)
            Positioned(
              top: -3,
              right: -3,
              child: Assets.icons.badge.svg(),
            ),

          if (showDone)
            Positioned(
              bottom: -4,
              right: -3,
              child: Assets.icons.circleBadg.svg(),
            ),
        ],
      ),
    );
  }
}
