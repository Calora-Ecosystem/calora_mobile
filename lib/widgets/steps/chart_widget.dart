import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum ChartType { monthly, weekly }

class ChartWidget extends StatelessWidget {
  final ChartType type;
  final List<double> primaryValues;
  final double total;
  final double? target; // maqsad chizig‘i

  const ChartWidget({
    super.key,
    required this.type,
    required this.primaryValues,
    required this.total,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    // O‘rtacha qiymatni hisoblaymiz
    final average = primaryValues.isEmpty
        ? 0
        : primaryValues.reduce((a, b) => a + b) / primaryValues.length;

    // eng katta qiymatni topamiz va 10% qo‘shamiz
    final maxValue = [
      ...primaryValues,
      if (target != null) target!,
      average,
    ].reduce((a, b) => a > b ? a : b);
    final maxY = maxValue * 1.1;

    return Column(
      children: [
        Row(
          children: [
            Text(
              type == ChartType.monthly ? "Oylik natijalar" : "Haftalik natijalar",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  average.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text("O'rtacha"),
              ],
            ),
            Column(
              children: [
                Text(
                  total.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text("Jami"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: type == ChartType.monthly ? 220 : 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: context.colors.neutralSecondary.withOpacity(0.2), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatNumber(value),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.colors.neutralPrimary,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (type == ChartType.monthly) {
                        final day = value.toInt() + 1;
                        if ([7, 14, 21, 28].contains(day)) {
                          return day.toString().text(14, 16, 400).c(context.colors.neutralPrimary);
                        }
                        return const SizedBox();
                      } else {
                        const days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return days[value.toInt()]
                              .text(14, 16, 400)
                              .c(context.colors.neutralPrimary);
                        }
                        return const SizedBox();
                      }
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null)
                    HorizontalLine(y: target!, color: context.colors.iconSoft, strokeWidth: 1.5),
                ],
              ),
              barGroups: primaryValues.asMap().entries.map((e) {
                final index = e.key;
                final value = e.value;

                final barColor = (target != null && value < target!)
                    ? context.colors.textSub
                    : context.colors.blueAccent;

                return BarChartGroupData(
                  x: index,
                  barsSpace: 2,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: barColor,
                      width: type == ChartType.monthly ? 4 : 12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}k";
    } else {
      return value.toInt().toString();
    }
  }
}
