import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:calora/domain/repo/report/report_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/report/weekly_report_format.dart';
import 'package:calora/presentation/report/weekly_report_story.dart';
import 'package:calora/presentation/report/widgets/weekly_kcal_chart.dart';
import 'package:calora/presentation/report/widgets/weekly_steps_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Profile → "Weekly calorie report": last week's kcal chart (steps chart
/// when no food was logged) with ‹ › to browse earlier weeks, and a button
/// that opens the full [WeeklyReportStory].
///
/// Everything on the card says what it measures — the title names the metric,
/// the chart has a caption and a legend for the bar colours and the norm line,
/// and every number carries its unit.
class WeeklyReportSection extends StatefulWidget {
  const WeeklyReportSection({super.key});

  /// How far back the user can browse.
  static const maxWeeksBack = 12;

  @override
  State<WeeklyReportSection> createState() => _WeeklyReportSectionState();
}

class _WeeklyReportSectionState extends State<WeeklyReportSection> {
  final _repo = getIt<ReportRepo>();
  final _cache = <int, WeeklyReport>{};

  /// 0 = last week, 1 = the week before, …
  int _offset = 0;
  bool _failed = false;

  WeeklyReport? get _report => _cache[_offset];

  static const _overColor = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final offset = _offset;
    if (_cache.containsKey(offset)) return;
    setState(() => _failed = false);
    try {
      final start = lastWeekStart().subtract(Duration(days: 7 * offset));
      final report = await _repo.getWeekly(start);
      if (!mounted) return;
      setState(() => _cache[offset] = report);
    } catch (_) {
      if (mounted && offset == _offset) setState(() => _failed = true);
    }
  }

  void _shift(int delta) {
    setState(() => _offset += delta);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final report = _report;
    final hasData = report != null && !report.isEmpty;
    final food = report != null && report.hasFood;
    final steps = hasData && !food && report.hasSteps;

    final title = food
        ? 'wr_section_title_kcal'.tr()
        : steps
        ? 'wr_section_title_steps'.tr()
        : 'wr_section_title'.tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58AE8A), Color(0xFF2F7D5B)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.mintGreen.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: title
                    .text(17, 22, 700)
                    .c(Colors.white)
                    .auto(minSize: 13),
              ),
              _arrow(
                Icons.chevron_left_rounded,
                _offset < WeeklyReportSection.maxWeeksBack
                    ? () => _shift(1)
                    : null,
              ),
              _arrow(
                Icons.chevron_right_rounded,
                _offset > 0 ? () => _shift(-1) : null,
              ),
            ],
          ),
          const SizedBox(height: 2),
          (report == null
                  ? ''
                  : _offset == 0
                  ? '${'wr_last_week'.tr()} · ${weekRange(context, report)}'
                  : weekRange(context, report))
              .text(13, 17, 500)
              .c(Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 14),
          if (food || steps) ...[
            (food ? 'wr_chart_kcal_caption' : 'wr_chart_steps_caption')
                .tr()
                .text(12, 16, 600)
                .c(Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 6),
          ],
          SizedBox(
            height: 150,
            child: report == null
                ? Center(
                    child: _failed
                        ? TextButton(
                            onPressed: _load,
                            child: 'try_again'
                                .tr()
                                .text(15, 20, 600)
                                .c(Colors.white),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  )
                : food
                ? WeeklyKcalChart(
                    key: ValueKey(report.weekStart),
                    days: report.days,
                    norm: report.norms.kcal,
                    height: 150,
                  )
                : steps
                ? WeeklyStepsChart(
                    key: ValueKey(report.weekStart),
                    days: report.days,
                    norm: report.norms.step,
                    height: 150,
                  )
                : hasData
                ? Center(
                    child: '${report.activeDays}/7 ${'wr_active_days'.tr()}'
                        .text(22, 28, 800)
                        .c(Colors.white),
                  )
                : Center(
                    child: 'wr_section_empty'
                        .tr()
                        .text(14, 19, 500)
                        .c(Colors.white.withValues(alpha: 0.9))
                        .copyWith(textAlign: TextAlign.center),
                  ),
          ),
          if (food && report.norms.kcal > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendDot(Colors.white, 'wr_legend_in_norm'.tr()),
                _legendDot(_overColor, 'wr_legend_over'.tr()),
                _legendDash(
                  'wr_legend_norm'.tr(
                    namedArgs: {
                      'value':
                          '${formatInt(report.norms.kcal)} ${'wr_unit_kcal'.tr()}',
                    },
                  ),
                ),
              ],
            ),
          ] else if (steps && report.norms.step > 0) ...[
            const SizedBox(height: 10),
            _legendDash(
              'wr_legend_step_goal'.tr(
                namedArgs: {'value': formatInt(report.norms.step)},
              ),
            ),
          ],
          if (hasData) ...[
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: food
                    ? [
                        Expanded(
                          child: _stat(
                            formatInt(report.averages.kcal),
                            'wr_unit_kcal'.tr(),
                            'wr_stat_avg_kcal'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _stat(
                            '${report.daysInNorm}/7',
                            'wr_unit_days'.tr(),
                            'wr_stat_in_norm'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _stat(
                            '${report.streak}',
                            'wr_unit_days'.tr(),
                            'wr_stat_streak'.tr(),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: _stat(
                            formatInt(report.totals.steps),
                            '',
                            'wr_steps_total'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _stat(
                            '${report.activeDays}/7',
                            'wr_unit_days'.tr(),
                            'wr_active_days'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _stat(
                            '+${report.coins.earned}',
                            'coin',
                            'wr_coins_earned'.tr(),
                          ),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => WeeklyReportStory.open(context, report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E5C45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: 'wr_section_open'.tr().text(15, 20, 700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) => IconButton(
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    icon: Icon(
      icon,
      color: onTap == null
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.white,
    ),
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      label.text(11, 14, 500).c(Colors.white.withValues(alpha: 0.9)),
    ],
  );

  Widget _legendDash(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 4,
          height: 1.5,
          margin: const EdgeInsets.only(right: 2),
          color: Colors.white.withValues(alpha: 0.8),
        ),
      const SizedBox(width: 3),
      label.text(11, 14, 500).c(Colors.white.withValues(alpha: 0.9)),
    ],
  );

  /// A number with its unit (`1 850 kcal`, `5/7 days`) over a plain-language
  /// label of what it counts.
  Widget _stat(String value, String unit, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: FontFamily.inter,
            ),
          ),
        ),
        const SizedBox(height: 2),
        label
            .text(11, 14, 500)
            .c(Colors.white.withValues(alpha: 0.85))
            .copyWith(maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
