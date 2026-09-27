import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Seven kcal bars (Mon–Sun) drawn on a coloured story background, with a
/// dashed norm line. Bars grow in on first build.
///
/// In-norm days are solid white, days over the norm use [overColor], days
/// with no food logged are a faint stub.
class WeeklyKcalChart extends StatelessWidget {
  final List<WeeklyReportDay> days;
  final double norm;
  final double height;
  final bool showValues;
  final Color overColor;

  const WeeklyKcalChart({
    super.key,
    required this.days,
    required this.norm,
    this.height = 200,
    this.showValues = true,
    this.overColor = const Color(0xFFFFD166),
  });

  static const _labelHeight = 18.0;
  static const _valueHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final maxKcal = days.fold<double>(0, (m, d) => d.kcal > m ? d.kcal : m);
    final top = [maxKcal, norm * 1.15, 1.0].reduce((a, b) => a > b ? a : b);
    final barArea = height - _labelHeight - (showValues ? _valueHeight : 0);
    const white = Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              if (norm > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _labelHeight + barArea * (norm / top),
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashPainter(white.withValues(alpha: 0.7)),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(child: _bar(days[i], i, top, barArea, t)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(
    WeeklyReportDay day,
    int index,
    double top,
    double area,
    double t,
  ) {
    final logged = day.isLogged;
    final over = logged && norm > 0 && day.kcal > norm * 1.1;
    final color = !logged
        ? Colors.white.withValues(alpha: 0.22)
        : over
        ? overColor
        : day.inNorm
        ? Colors.white
        : Colors.white.withValues(alpha: 0.7);
    final barHeight = logged
        ? (area * (day.kcal / top) * t).clamp(6.0, area)
        : 6.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showValues)
            SizedBox(
              height: _valueHeight,
              child: logged
                  ? Opacity(
                      opacity: t,
                      child: '${day.kcal.round()}'
                          .text(10, 14, 600)
                          .c(Colors.white)
                          .auto(minSize: 7),
                    )
                  : null,
            ),
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(
            height: _labelHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: 'wr_day_${index + 1}'
                  .tr()
                  .text(11, 14, 500)
                  .c(Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
