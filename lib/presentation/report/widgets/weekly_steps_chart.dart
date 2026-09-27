import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Seven step bars (Mon–Sun) on a coloured background with a dashed step-norm
/// line — the activity counterpart of `WeeklyKcalChart`. Days that reached
/// the norm are solid white, others translucent, zero-step days a stub.
class WeeklyStepsChart extends StatelessWidget {
  final List<WeeklyReportDay> days;
  final double norm;
  final double height;
  final bool showValues;

  const WeeklyStepsChart({
    super.key,
    required this.days,
    required this.norm,
    this.height = 160,
    this.showValues = true,
  });

  static const _labelHeight = 18.0;
  static const _valueHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final maxSteps = days.fold<double>(0, (m, d) => d.steps > m ? d.steps : m);
    final top = [maxSteps, norm * 1.15, 1.0].reduce((a, b) => a > b ? a : b);
    final barArea = height - _labelHeight - (showValues ? _valueHeight : 0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
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
                  painter: _DashPainter(Colors.white.withValues(alpha: 0.7)),
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
      ),
    );
  }

  Widget _bar(
    WeeklyReportDay day,
    int index,
    double top,
    double area,
    double t,
  ) {
    final walked = day.steps > 0;
    final reached = norm > 0 && day.steps >= norm;
    final color = !walked
        ? Colors.white.withValues(alpha: 0.22)
        : reached
        ? Colors.white
        : Colors.white.withValues(alpha: 0.6);
    final barHeight = walked
        ? (area * (day.steps / top) * t).clamp(6.0, area)
        : 6.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showValues)
            SizedBox(
              height: _valueHeight,
              child: walked
                  ? Opacity(
                      opacity: t,
                      child: _short(
                        day.steps,
                      ).text(10, 14, 600).c(Colors.white).auto(minSize: 7),
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

  /// `8.2k` above 1000, the plain number below.
  static String _short(double steps) => steps >= 1000
      ? '${(steps / 1000).toStringAsFixed(1)}k'
      : '${steps.round()}';
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
