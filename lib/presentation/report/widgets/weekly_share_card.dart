import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:calora/presentation/report/weekly_report_format.dart';
import 'package:calora/presentation/report/widgets/weekly_kcal_chart.dart';
import 'package:calora/presentation/report/widgets/weekly_steps_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The 9:16 card the user posts to a story. Laid out at [size] logical pixels
/// and captured at 4× (1080×1920). Kcal numbers are hidden unless
/// [showCalories] — weight / diet numbers are personal, streak and steps are
/// the brag-worthy bits.
class WeeklyShareCard extends StatelessWidget {
  final WeeklyReport report;
  final bool showCalories;

  /// The invite code printed in the footer; filled right before capture.
  final String? inviteCode;

  const WeeklyShareCard({
    super.key,
    required this.report,
    required this.showCalories,
    this.inviteCode,
  });

  static const size = Size(270, 480);

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final badge = report.badges.isNotEmpty ? report.badges.first : null;
    // A week without food is shown by its activity instead of empty kcal bars.
    final food = report.hasFood;

    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E5C45), Color(0xFF58AE8A)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Assets.images.caloraLogo.image(height: 16),
                  ),
                  const Spacer(),
                  weekRange(
                    context,
                    report,
                  ).text(10, 14, 500).c(white.withValues(alpha: 0.85)),
                ],
              ),
              const SizedBox(height: 18),
              'wr_share_card_title'
                  .tr(namedArgs: {'name': report.name})
                  .text(22, 27, 700)
                  .c(white)
                  .auto(maxLines: 2, minSize: 16),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  '${food ? report.daysInNorm : report.activeDays}/7'
                      .text(44, 46, 800)
                      .c(white),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: (food ? 'wr_share_in_norm' : 'wr_active_days')
                        .tr()
                        .text(13, 16, 600)
                        .c(white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (food)
                WeeklyKcalChart(
                  days: report.days,
                  norm: report.norms.kcal,
                  height: 130,
                  showValues: showCalories,
                )
              else
                WeeklyStepsChart(
                  days: report.days,
                  norm: report.norms.step,
                  height: 130,
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: report.streak > 0 || food
                        ? _tile('🔥', '${report.streak}', 'wr_streak'.tr())
                        : _tile(
                            '🪙',
                            '+${report.coins.earned}',
                            'wr_coins_earned'.tr(),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tile(
                      '👟',
                      formatInt(report.totals.steps),
                      'steps'.tr().toLowerCase(),
                    ),
                  ),
                ],
              ),
              if (showCalories && food) ...[
                const SizedBox(height: 8),
                _tile(
                  '🍽',
                  '${formatInt(report.averages.kcal)} ${'kcal'.tr()}',
                  'wr_daily_avg'.tr(),
                ),
              ],
              if (badge != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: '${badgeEmoji(badge)} ${'wr_badge_$badge'.tr()}'
                      .text(11, 14, 700)
                      .c(const Color(0xFF3B2F00)),
                ),
              ],
              const Spacer(),
              if (inviteCode != null)
                'wr_share_join'
                    .tr(namedArgs: {'code': inviteCode!})
                    .text(11, 15, 600)
                    .c(white),
              'calora.uz'.text(10, 14, 500).c(white.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String emoji, String value, String label) {
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          emoji.text(16, 20, 400),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value.text(14, 18, 700).c(white).auto(minSize: 9),
                label
                    .text(9, 12, 500)
                    .c(white.withValues(alpha: 0.8))
                    .auto(minSize: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
