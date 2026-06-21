import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum ChartType { monthly, weekly }

class ChartWidget extends StatelessWidget {
  final ChartType type;
  final List<double> primaryValues;
  final double? target;

  /// First calendar day the chart represents — Monday of the week (weekly)
  /// or the 1st of the month (monthly). Lets each bar map back to a real
  /// date for localized tooltips. Null falls back to index-only labels.
  final DateTime? periodStart;

  const ChartWidget({
    super.key,
    required this.type,
    required this.primaryValues,
    this.target,
    this.periodStart,
  });

  // ── Localized short names (intl locale-data free, so they never throw
  //    on locales without bundled symbols) ──────────────────────────────
  static const Map<String, List<String>> _weekdayShort = {
    'uz': ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Ya'],
    'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };

  static const Map<String, List<String>> _monthShort = {
    'uz': ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'],
    'ru': ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  };

  List<String> _weekdays(BuildContext context) =>
      _weekdayShort[context.locale.languageCode] ?? _weekdayShort['en']!;

  List<String> _months(BuildContext context) =>
      _monthShort[context.locale.languageCode] ?? _monthShort['en']!;

  @override
  Widget build(BuildContext context) {
    // Weekly is always exactly 7 bars. Monthly used to be hard-coded
    // to 30, which mis-rendered February (28/29) and 31-day months
    // (Jan, Mar, May, …). Use the supplied `primaryValues` length —
    // `StepsManager._buildMonthlySteps` already sizes it with
    // `DateUtils.getDaysInMonth(target.year, target.month)`.
    final int itemCount = type == ChartType.weekly
        ? 7
        : (primaryValues.isEmpty ? 30 : primaryValues.length);

    final values = List<double>.generate(
      itemCount,
      (i) => i < primaryValues.length ? primaryValues[i] : 0,
    );

    final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0;
    final total = values.isNotEmpty ? values.reduce((a, b) => a + b) : 0;

    final maxValue = [...values, if (target != null) target!, average].reduce((a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 10.0 : maxValue * 1.1;

    final double minBarY = maxY * 0.02;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              alignment: type == ChartType.monthly ? BarChartAlignment.spaceBetween : BarChartAlignment.spaceAround,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                getDrawingVerticalLine: (value) => FlLine(color: const Color(0xFFF0F0F0), dashArray: [2, 2]),
                getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF0F0F0), dashArray: [2, 2]),
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
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.colors.primarySolid,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final int x = group.x.toInt();
                    final double realValue = (x >= 0 && x < values.length) ? values[x] : 0;

                    return BarTooltipItem(
                      '${_tooltipDateLabel(context, x)}\n',
                      TextStyle(
                        color: context.colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: '${realValue.toStringAsFixed(0)} ${Strings.steps}',
                          style: TextStyle(
                            color: context.colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null) HorizontalLine(y: target!, color: context.colors.iconSoft, strokeWidth: 1),
                ],
              ),
              barGroups: values.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final double displayY = value == 0 ? minBarY : value;
                final color = context.colors.blueAccent;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: displayY,
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
      if ([1, 7, 14, 21, 28].contains(day)) {
        return day.toString().text(13, 16, 400).c(context.colors.neutralPrimary);
      }
      return const SizedBox.shrink();
    } else {
      final days = _weekdays(context);
      if (index >= 0 && index < days.length) {
        return days[index].text(13, 16, 400).c(context.colors.neutralPrimary);
      }
      return const SizedBox.shrink();
    }
  }

  /// Localized date shown at the top of a bar's tooltip, e.g. "15 Iyn"
  /// (monthly) or "Du, 22 Iyn" (weekly).
  String _tooltipDateLabel(BuildContext context, int index) {
    if (periodStart == null) {
      // No reference date — fall back to a bare index label.
      return type == ChartType.weekly
          ? (_weekdays(context).elementAtOrNull(index) ?? '')
          : '${index + 1}';
    }
    final months = _months(context);
    if (type == ChartType.monthly) {
      final date = DateTime(periodStart!.year, periodStart!.month, index + 1);
      return '${date.day} ${months[date.month - 1]}';
    } else {
      final date = periodStart!.add(Duration(days: index));
      final wd = _weekdays(context).elementAtOrNull(index) ?? '';
      return '$wd, ${date.day} ${months[date.month - 1]}';
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
