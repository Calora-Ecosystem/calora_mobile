import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:calora/domain/repo/referral/referral_repo.dart';
import 'package:calora/domain/repo/report/report_repo.dart';
import 'package:calora/presentation/report/weekly_report_format.dart';
import 'package:calora/presentation/report/widgets/weekly_kcal_chart.dart';
import 'package:calora/presentation/report/widgets/weekly_share_card.dart';
import 'package:calora/presentation/report/widgets/weekly_steps_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

const String _shareLink = 'https://calora.uz/get-app?utm_source=weekly_report';

/// Last week's report as full-screen story slides (Instagram-style): tap the
/// right side to go on, the left side to go back, hold to pause. The last
/// slide renders [WeeklyShareCard] and shares it as an image.
///
/// Shown once per week, on the first launch of the week — see [maybeShow].
class WeeklyReportStory extends StatefulWidget {
  final WeeklyReport report;

  const WeeklyReportStory({super.key, required this.report});

  /// Opens last week's report if it hasn't been shown yet. Skipped for users
  /// still in the first-run tour and for weeks with nothing recorded at all
  /// (a week with only steps still gets a report). A failed request is not
  /// marked as shown, so the next launch tries again.
  static Future<void> maybeShow(BuildContext context) async {
    final store = StepLedgerStore();
    if (!store.isFeatureTourShown()) return;

    final weekStart = lastWeekStart();
    final weekKey = DateFormat('yyyyMMdd').format(weekStart);
    if (store.isWeeklyReportShown(weekKey)) return;

    final WeeklyReport report;
    try {
      report = await getIt<ReportRepo>().getWeekly(weekStart);
    } catch (_) {
      return;
    }

    await store.setWeeklyReportShown(weekKey);
    if (report.isEmpty) return;
    if (!context.mounted) return;

    await open(context, report);
  }

  /// Opens the story for any week — also used by the Profile section.
  static Future<void> open(BuildContext context, WeeklyReport report) {
    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => WeeklyReportStory(report: report),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  State<WeeklyReportStory> createState() => _WeeklyReportStoryState();
}

enum _Slide { intro, calories, habits, activity, you, progress, share }

class _WeeklyReportStoryState extends State<WeeklyReportStory>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 7);

  /// Fewer food days than this → the intro nudges to log more.
  static const _fullLogDays = 3;

  /// Only slides with something to say: a week with steps but no food skips
  /// the food slides instead of showing empty charts.
  late final List<_Slide> _slides = [
    _Slide.intro,
    if (_r.hasFood) _Slide.calories,
    if (_r.hasFood && _r.topFood != null) _Slide.habits,
    if (_r.hasSteps || _r.hasWater) _Slide.activity,
    if (_hasYouSlide) _Slide.you,
    if (_hasProgressSlide) _Slide.progress,
    _Slide.share,
  ];

  bool get _hasYouSlide =>
      _r.body.hasWeight ||
      !_r.course.isEmpty ||
      _r.coins.earned > 0 ||
      _r.coins.balance > 0 ||
      _r.friendsInvited > 0 ||
      _r.stepGroups > 0;

  bool get _hasProgressSlide =>
      _r.streak > 0 ||
      _r.badges.isNotEmpty ||
      _r.kcalAvgChangePercent != null ||
      _r.stepsChangePercent != null;

  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _slideDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _next();
        });

  final _shot = ScreenshotController();
  int _index = 0;
  bool _showCalories = false;
  bool _sharing = false;
  String? _inviteCode;

  WeeklyReport get _r => widget.report;

  _Slide get _slide => _slides[_index];

  @override
  void initState() {
    super.initState();
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    if (_slide == _Slide.share) {
      // The share slide waits for the user.
      _progress.value = 1;
    } else {
      _progress.forward(from: 0);
    }
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _goTo(_index + 1);
    } else if (_slide != _Slide.share) {
      _close();
    }
  }

  void _prev() {
    if (_index > 0) {
      _goTo(_index - 1);
    } else {
      _progress.forward(from: 0);
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Every share gets a fresh invite code (same rule as the Invite screen).
      String? code;
      try {
        code = await getIt<ReferralRepo>().newCode();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _inviteCode = code);
      await WidgetsBinding.instance.endOfFrame;

      final bytes = await _shot.capture(
        pixelRatio: 4,
        delay: const Duration(milliseconds: 60),
      );
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/calora_week.png',
      ).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: code == null
              ? _shareLink
              : 'wr_share_text'.tr(
                  namedArgs: {'code': code, 'link': _shareLink},
                ),
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
    } catch (_) {
      // Share sheet dismissed or capture failed — nothing to recover.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[_slide]!;
    return Material(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (_slide == _Slide.share) return;
          final width = MediaQuery.sizeOf(context).width;
          details.globalPosition.dx < width / 3 ? _prev() : _next();
        },
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) {
          if (_slide != _Slide.share) _progress.forward();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_slide),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: _buildSlide(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: i < _index
                              ? 1
                              : i == _index
                              ? _progress.value
                              : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide() => switch (_slide) {
    _Slide.intro => _intro(),
    _Slide.calories => _calories(),
    _Slide.habits => _habits(),
    _Slide.activity => _activity(),
    _Slide.you => _you(),
    _Slide.progress => _progressSlide(),
    _Slide.share => _shareSlide(),
  };

  // ── Slides ────────────────────────────────────────────────────────────────

  Widget _intro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Float(child: Assets.images.premiumFire.image(height: 110)),
        const SizedBox(height: 28),
        'wr_hello'
            .tr(namedArgs: {'name': _r.name})
            .text(30, 36, 800)
            .c(Colors.white)
            .copyWith(textAlign: TextAlign.center),
        const SizedBox(height: 10),
        (!_r.hasFood
                ? 'wr_intro_no_food'.tr()
                : _r.loggedDays < _fullLogDays
                ? 'wr_intro_short'.tr(namedArgs: {'days': '${_r.loggedDays}'})
                : 'wr_intro_sub'.tr())
            .text(17, 24, 500)
            .c(_soft)
            .copyWith(textAlign: TextAlign.center),
        const SizedBox(height: 18),
        _pill(weekRange(context, _r)),
        const SizedBox(height: 10),
        _pill('${_r.activeDays}/7 ${'wr_active_days'.tr()}'),
        const SizedBox(height: 48),
        'wr_tap_hint'.tr().text(13, 18, 500).c(_faint),
      ],
    );
  }

  Widget _calories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('wr_calories_title'.tr(), '🍽'),
        const Spacer(),
        _CountUp(
          value: _r.averages.kcal,
          builder: (v) => '${formatInt(v)} ${'kcal'.tr()}'
              .text(44, 50, 800)
              .c(Colors.white)
              .auto(minSize: 28),
        ),
        'wr_daily_avg'.tr().text(15, 20, 500).c(_soft),
        const SizedBox(height: 28),
        WeeklyKcalChart(days: _r.days, norm: _r.norms.kcal, height: 220),
        const SizedBox(height: 10),
        if (_r.norms.kcal > 0)
          Row(
            children: [
              CustomPaint(size: const Size(18, 1), painter: _LegendDash()),
              const SizedBox(width: 6),
              '${'wr_norm_label'.tr()} · ${formatInt(_r.norms.kcal)} ${'kcal'.tr()}'
                  .text(12, 16, 500)
                  .c(_soft),
            ],
          ),
        const Spacer(),
        _glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              'wr_days_in_norm'
                  .tr(namedArgs: {'count': '${_r.daysInNorm}'})
                  .text(17, 23, 700)
                  .c(Colors.white),
              const SizedBox(height: 4),
              'wr_week_total'
                  .tr(namedArgs: {'kcal': formatInt(_r.totals.kcal)})
                  .text(14, 19, 500)
                  .c(_soft),
            ],
          ),
        ),
      ],
    );
  }

  Widget _habits() {
    final food = _r.topFood;
    final heaviest = _r.heaviestDay;
    final heaviestKcal = heaviest == null
        ? 0.0
        : _r.days.firstWhere((d) => _sameDay(d.date, heaviest)).kcal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('wr_habits_title'.tr(), '🥗'),
        const SizedBox(height: 24),
        if (food != null)
          _glass(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (food.coverUrl ?? '').isNotEmpty
                      ? CustomCachedNetworkImage.thumbnail(
                          imageUrl: food.coverUrl,
                          height: 72,
                          width: 72,
                          radius: 16,
                        )
                      : Container(
                          height: 72,
                          width: 72,
                          color: Colors.white.withValues(alpha: 0.2),
                          alignment: Alignment.center,
                          child: '🍲'.text(34, 40, 400),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      'wr_top_food'.tr().text(13, 17, 500).c(_soft),
                      const SizedBox(height: 2),
                      food.name
                          .text(20, 25, 700)
                          .c(Colors.white)
                          .auto(maxLines: 2, minSize: 14),
                      'wr_times'
                          .tr(namedArgs: {'count': '${food.count}'})
                          .text(14, 18, 600)
                          .c(_accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _stat('${_r.totals.mealCount}', 'wr_meals_logged'.tr()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: heaviest == null
                  ? const SizedBox.shrink()
                  : _stat(
                      weekdayName(heaviest),
                      '${'wr_heaviest_day'.tr()} · ${formatInt(heaviestKcal)} ${'kcal'.tr()}',
                    ),
            ),
          ],
        ),
        const Spacer(),
        'wr_meal_split'.tr().text(16, 21, 700).c(Colors.white),
        const SizedBox(height: 12),
        _MenuSplit(kcalByMenu: _r.kcalByMenu),
        const Spacer(),
      ],
    );
  }

  Widget _activity() {
    final steps = _r.totals.steps;
    final km = steps * 0.00075;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('wr_activity_title'.tr(), '🚶'),
        const Spacer(),
        _CountUp(
          value: steps,
          builder: (v) =>
              formatInt(v).text(52, 56, 800).c(Colors.white).auto(minSize: 32),
        ),
        'wr_steps_total'.tr().text(16, 21, 500).c(_soft),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill('wr_distance'.tr(namedArgs: {'km': km.toStringAsFixed(1)})),
            _pill(
              'wr_steps_avg'.tr(
                namedArgs: {'steps': formatInt(_r.averages.steps)},
              ),
            ),
          ],
        ),
        if (steps > 0) ...[
          const SizedBox(height: 20),
          WeeklyStepsChart(days: _r.days, norm: _r.norms.step, height: 150),
        ],
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _stat(
                _r.mostActiveDay == null ? '—' : weekdayName(_r.mostActiveDay!),
                'wr_most_active'.tr(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _r.norms.step > 0
                  ? _stat(
                      '${_r.stepDaysInNorm}/7',
                      '${'wr_step_goal_days'.tr()} · ${formatInt(_r.norms.step)}',
                    )
                  : _stat('+${_r.coinsEarned} 🪙', 'wr_coins_earned'.tr()),
            ),
          ],
        ),
        if (_r.hasWater) ...[
          const SizedBox(height: 12),
          _glass(
            child: Row(
              children: [
                '💧'.text(28, 32, 400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      '${'wr_water'.tr()} · ${_r.totals.water.toStringAsFixed(1)} ${'liter'.tr()}'
                          .text(17, 22, 700)
                          .c(Colors.white),
                      if (_r.norms.water > 0)
                        'wr_water_days'
                            .tr(namedArgs: {'count': '${_r.waterDaysInNorm}'})
                            .text(13, 18, 500)
                            .c(_soft),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Profile, coins, course, invites and groups — everything that isn't food
  /// or steps.
  Widget _you() {
    final body = _r.body;
    final tiles = <Widget>[
      if (_r.coins.earned > 0)
        _stat('+${formatInt(_r.coins.earned)} 🪙', 'wr_coins_week'.tr()),
      if (_r.coins.balance > 0)
        _stat('${formatInt(_r.coins.balance)} 🪙', 'wr_coins_balance'.tr()),
      if (_r.coins.spent > 0)
        _stat(formatInt(_r.coins.spent), 'wr_coins_spent'.tr()),
      if (_r.course.lessons > 0)
        _stat('${_r.course.lessons} 📚', 'wr_lessons_done'.tr()),
      if (_r.course.workouts > 0)
        _stat('${_r.course.workouts} 🏋️', 'wr_workouts_done'.tr()),
      if (_r.course.exercises > 0)
        _stat('${_r.course.exercises} 🤸', 'wr_exercises_done'.tr()),
      if (_r.friendsInvited > 0)
        _stat('${_r.friendsInvited} 🤝', 'wr_friends_invited'.tr()),
      if (_r.stepGroups > 0)
        _stat('${_r.stepGroups} 👥', 'wr_step_groups'.tr()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('wr_you_title'.tr(), '🎯'),
        const SizedBox(height: 24),
        if (body.hasWeight) ...[_weightCard(body), const SizedBox(height: 12)],
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            // Two rows fit under the weight card, three without it.
            children: tiles.take(body.hasWeight ? 4 : 6).toList(),
          ),
        ),
        if (!_r.hasFood) ...[
          const SizedBox(height: 12),
          _glass(child: 'wr_food_nudge'.tr().text(15, 20, 600).c(Colors.white)),
        ],
      ],
    );
  }

  Widget _weightCard(WeeklyBody body) {
    final progress = body.goalProgress;
    final change = body.changeSinceStart;
    final kg = 'pw_weight_unit'.tr();
    final reached = body.targetWeight > 0 && body.toTarget < 0.1;

    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'wr_weight_now'.tr().text(13, 17, 500).c(_soft),
                    '${formatKg(body.weight)} $kg'
                        .text(34, 40, 800)
                        .c(Colors.white),
                  ],
                ),
              ),
              if (body.bmi > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    'wr_bmi'.tr().text(13, 17, 500).c(_soft),
                    body.bmi.toStringAsFixed(1).text(22, 28, 800).c(_accent),
                  ],
                ),
            ],
          ),
          if (body.targetWeight > 0) ...[
            const SizedBox(height: 10),
            (reached
                    ? 'wr_weight_reached'.tr()
                    : 'wr_weight_target'.tr(
                        namedArgs: {
                          'kg': formatKg(body.targetWeight),
                          'left': formatKg(body.toTarget),
                        },
                      ))
                .text(14, 19, 600)
                .c(Colors.white),
          ],
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: _accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
          if (change.abs() >= 0.1) ...[
            const SizedBox(height: 8),
            'wr_weight_change'
                .tr(
                  namedArgs: {
                    'kg': '${change > 0 ? '+' : '−'}${formatKg(change.abs())}',
                  },
                )
                .text(13, 18, 500)
                .c(_soft),
          ],
        ],
      ),
    );
  }

  Widget _progressSlide() {
    final kcalChange = _r.kcalAvgChangePercent;
    final stepsChange = _r.stepsChangePercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('wr_progress_title'.tr(), '📈'),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The streak counts food days only; a steps-only week shows its
            // active days instead of a discouraging zero.
            _CountUp(
              value: (_r.streak > 0 ? _r.streak : _r.activeDays).toDouble(),
              builder: (v) => '${v.round()}'.text(72, 74, 800).c(Colors.white),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  (_r.streak > 0
                          ? '🔥 ${'wr_streak'.tr()}'
                          : '⚡ ${'wr_active_days'.tr()}')
                      .text(18, 23, 600)
                      .c(_soft),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              'wr_vs_last_week'.tr().text(14, 19, 500).c(_soft),
              const SizedBox(height: 10),
              if (kcalChange == null && stepsChange == null)
                'wr_no_compare'.tr().text(15, 20, 600).c(Colors.white)
              else ...[
                if (kcalChange != null)
                  // Fewer calories is the usual goal, so a drop reads as good.
                  _changeRow(
                    'wr_avg_kcal'.tr(),
                    kcalChange,
                    positiveIsGood: false,
                  ),
                if (kcalChange != null && stepsChange != null)
                  const SizedBox(height: 8),
                if (stepsChange != null)
                  _changeRow('steps'.tr(), stepsChange, positiveIsGood: true),
              ],
            ],
          ),
        ),
        const Spacer(),
        if (_r.badges.isNotEmpty) ...[
          'wr_badges'.tr().text(16, 21, 700).c(Colors.white),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in _r.badges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: '${badgeEmoji(badge)} ${'wr_badge_$badge'.tr()}'
                      .text(14, 18, 700)
                      .c(const Color(0xFF3B2F00)),
                ),
            ],
          ),
        ],
        const Spacer(),
      ],
    );
  }

  Widget _shareSlide() {
    return Column(
      children: [
        _title('wr_share_title'.tr(), '📸'),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: FittedBox(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Screenshot(
                    controller: _shot,
                    child: WeeklyShareCard(
                      report: _r,
                      showCalories: _showCalories,
                      inviteCode: _inviteCode,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // No food → the card has no calories to reveal.
        if (_r.hasFood)
          Row(
            children: [
              Expanded(
                child: 'wr_show_numbers'.tr().text(15, 20, 600).c(Colors.white),
              ),
              Switch.adaptive(
                value: _showCalories,
                activeTrackColor: _accent,
                onChanged: (v) => setState(() => _showCalories = v),
              ),
            ],
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _sharing ? null : _share,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E5C45),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: 'share_action'.tr().text(16, 20, 700),
          ),
        ),
        TextButton(
          onPressed: _close,
          child: 'close'.tr().text(15, 20, 600).c(_soft),
        ),
      ],
    );
  }

  // ── Building blocks ───────────────────────────────────────────────────────

  static const _soft = Color(0xE6FFFFFF);
  static const _faint = Color(0x99FFFFFF);
  static const _accent = Color(0xFFFFD166);

  static const _gradients = <_Slide, List<Color>>{
    _Slide.intro: [Color(0xFF58AE8A), Color(0xFF2F7D5B)],
    _Slide.calories: [Color(0xFF1E5C45), Color(0xFF46A758)],
    _Slide.habits: [Color(0xFFF2994A), Color(0xFFD9573B)],
    _Slide.activity: [Color(0xFF0090FF), Color(0xFF0058C4)],
    _Slide.you: [Color(0xFF12A594), Color(0xFF0D6E63)],
    _Slide.progress: [Color(0xFF6E56CF), Color(0xFF45338F)],
    _Slide.share: [Color(0xFF16261F), Color(0xFF24473A)],
  };

  Widget _title(String text, String emoji) => Row(
    children: [
      emoji.text(24, 28, 400),
      const SizedBox(width: 10),
      Expanded(child: text.text(24, 30, 800).c(Colors.white)),
    ],
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: text.text(14, 18, 600).c(Colors.white),
  );

  Widget _glass({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: child,
  );

  Widget _stat(String value, String label) => _glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        value.text(20, 25, 800).c(Colors.white).auto(minSize: 13),
        const SizedBox(height: 2),
        label.text(12, 16, 500).c(_soft).auto(maxLines: 2, minSize: 9),
      ],
    ),
  );

  Widget _changeRow(
    String label,
    double change, {
    required bool positiveIsGood,
  }) {
    final good = positiveIsGood ? change >= 0 : change <= 0;
    return Row(
      children: [
        Expanded(child: label.text(16, 21, 600).c(Colors.white)),
        Icon(
          change >= 0
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 18,
          color: good ? const Color(0xFF9BF2B8) : _accent,
        ),
        const SizedBox(width: 4),
        formatPercent(
          change,
        ).text(16, 21, 800).c(good ? const Color(0xFF9BF2B8) : _accent),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Kcal share per meal as one stacked bar with a legend underneath.
class _MenuSplit extends StatelessWidget {
  final Map<String, double> kcalByMenu;

  const _MenuSplit({required this.kcalByMenu});

  static const _menus = [
    ('Breakfast', 'breakfast', Color(0xFFFFD166)),
    ('Lunch', 'lunch', Color(0xFFFFFFFF)),
    ('Dinner', 'dinner', Color(0xFF6B2E1F)),
    ('Snack', 'snacks', Color(0xFFFFB38A)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = kcalByMenu.values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (key, _, color) in _menus)
                  if ((kcalByMenu[key] ?? 0) > 0)
                    Expanded(
                      flex: ((kcalByMenu[key]! / total) * 1000).round().clamp(
                        1,
                        1000,
                      ),
                      child: ColoredBox(color: color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final (key, label, color) in _menus)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  '${label.tr()} ${((kcalByMenu[key] ?? 0) / total * 100).round()}%'
                      .text(13, 17, 600)
                      .c(Colors.white),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Counts a number up from zero when the slide appears.
class _CountUp extends StatelessWidget {
  final double value;
  final Widget Function(double value) builder;

  const _CountUp({required this.value, required this.builder});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: const Duration(milliseconds: 1100),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => builder(v),
  );
}

/// Gentle up-and-down bob for the intro illustration.
class _Float extends StatefulWidget {
  final Widget child;

  const _Float({required this.child});

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
      child: child,
    ),
    child: widget.child,
  );
}

class _LegendDash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_LegendDash oldDelegate) => false;
}
