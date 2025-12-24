import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum ChartType { monthly, weekly }

class ChartWidget extends StatelessWidget {
  final ChartType type;
  final List<double> primaryValues;
  final double? target;

  const ChartWidget({super.key, required this.type, required this.primaryValues, this.target});

  @override
  Widget build(BuildContext context) {
    final int itemCount = type == ChartType.weekly ? 7 : 30;

    // 🔹 Agar kam bo‘lsa, 0 bilan to‘ldiramiz
    final values = List<double>.generate(
      itemCount,
      (i) => i < primaryValues.length ? primaryValues[i] : 0,
    );

    final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0;
    final total = values.isNotEmpty ? values.reduce((a, b) => a + b) : 0;

    final maxValue = [
      ...values,
      if (target != null) target!,
      average,
    ].reduce((a, b) => a > b ? a : b);

    final maxY = maxValue == 0 ? 10 : maxValue * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (type == ChartType.monthly ? Strings.monthlyResults : Strings.weeklyResults)
            .text(14, 18, 600)
            .c(context.colors.neutralPrimary),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(context, average.toStringAsFixed(0), Strings.avarage),
            _buildStat(context, total.toStringAsFixed(0), Strings.total),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: type == ChartType.monthly ? 220 : 160,
          child: BarChart(
            BarChartData(
              alignment: type == ChartType.monthly
                  ? BarChartAlignment.spaceBetween
                  : BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                getDrawingVerticalLine: (value) =>
                    FlLine(color: const Color(0xFFF0F0F0), dashArray: [2, 2]),
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: const Color(0xFFF0F0F0), dashArray: [2, 2]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) =>
                        _formatNumber(value).text(10, 16, 400).c(context.colors.neutralPrimary),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => _buildBottomTitle(context, value.toInt()),
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles()),
                topTitles: AxisTitles(sideTitles: SideTitles()),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.colors.primarySolid,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      TextStyle(
                        color: context.colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null)
                    HorizontalLine(y: target!, color: context.colors.iconSoft, strokeWidth: 1),
                ],
              ),
              barGroups: values.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;

                final adjustedValue = value == 0 ? (maxY * 0.05) : value;
                final color = context.colors.blueAccent;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: adjustedValue,
                      color: color,
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

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        value.text(20, 24, 600).c(context.colors.neutralPrimary),
        label.text(14, 16, 400).c(context.colors.textSub),
      ],
    );
  }

  Widget _buildBottomTitle(BuildContext context, int index) {
    if (type == ChartType.monthly) {
      final day = index + 1;
      if ([7, 14, 21, 28].contains(day)) {
        return day.toString().text(14, 16, 400).c(context.colors.neutralPrimary);
      }
      return const SizedBox();
    } else {
      const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      if (index >= 0 && index < days.length) {
        return days[index].text(14, 16, 400).c(context.colors.neutralPrimary);
      }
      return const SizedBox();
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return value.toInt().toString();
    }
  }
}
