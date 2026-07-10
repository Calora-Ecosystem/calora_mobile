import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/video_player/animated_asset_view.dart';
import 'package:calora/common/widgets/video_player/looping_muted_video_player.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/premium_sheet.dart';
import 'package:calora/widgets/video/about_video_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Keeps the page readable on tablets / large screens instead of stretching.
const double _kMaxContentWidth = 600;

double _hpad(BuildContext c) => MediaQuery.sizeOf(c).width < 360 ? 16 : 20;

/// Centered, width-capped, horizontally padded wrapper for a section.
Widget _wrap(BuildContext context, Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _hpad(context)),
        child: child,
      ),
    ),
  );
}

@RoutePage()
class PremiumFeaturesPage extends StatefulWidget {
  const PremiumFeaturesPage({super.key});

  @override
  State<PremiumFeaturesPage> createState() => _PremiumFeaturesPageState();
}

class _PremiumFeaturesPageState extends State<PremiumFeaturesPage> {
  _Journey _journey = _Journey.fallback();

  // Real, gender-aware content pulled from the backend (the `/course`
  // endpoint is already filtered by the user's gender server-side).
  bool _contentLoading = true;
  LessonRequest? _lesson;
  ExercisesRequest? _exercise;

  /// Single source of truth for the "50% off" countdown so the hero and the
  /// closing CTA tick in perfect sync. Owned by the page (not the scrolled
  /// widgets) so it restarts on every open and is unaffected by scrolling.
  static const Duration _kOfferWindow = Duration(minutes: 10);
  final ValueNotifier<Duration> _offerRemaining =
      ValueNotifier<Duration>(_kOfferWindow);
  Timer? _offerTimer;

  static const List<String> _levels = [
    'Minimal',
    'Less',
    'Medium',
    'High',
    'Maximal',
  ];

  @override
  void initState() {
    super.initState();
    _startOfferCountdown();
    _loadProfile();
    _loadContent();
  }

  void _startOfferCountdown() {
    _offerRemaining.value = _kOfferWindow;
    _offerTimer?.cancel();
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _offerRemaining.value - const Duration(seconds: 1);
      _offerRemaining.value = next.isNegative ? Duration.zero : next;
    });
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerRemaining.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final ProfileRequest p = await getIt<ProfileStore>().getProfile();
      if (!mounted) return;
      setState(() => _journey = _Journey.fromProfile(p));
    } catch (_) {
      /* keep fallback */
    }
  }

  Future<void> _loadContent() async {
    try {
      final repo = getIt<CourseRepo>();
      final profile = await getIt<ProfileStore>().getProfile();
      final level = _levels.contains(profile.activityLevel)
          ? profile.activityLevel!
          : 'Medium';

      // Gender is applied inside getCourse() from the stored profile.
      final courses = await repo.getCourse();
      final videoCourse =
          courses.firstWhereOrNull((c) => (c.type ?? '') != 'Workout');
      final workoutCourse =
          courses.firstWhereOrNull((c) => c.type == 'Workout');

      LessonRequest? lesson;
      if (videoCourse?.id != null) {
        final lessons = await repo.getLessonsById(videoCourse!.id!);
        lesson = lessons.firstWhereOrNull((l) => l.isFree) ??
            (lessons.isNotEmpty ? lessons.first : null);
      }

      ExercisesRequest? exercise;
      if (workoutCourse?.id != null) {
        final workouts = await repo.getWorkout(workoutCourse!.id!, level);
        if (workouts.isNotEmpty) {
          final exercises =
              await repo.getExercisesByWorkoutId(workouts.first.id, level);
          exercise = exercises.isNotEmpty ? exercises.first : null;
        }
      }

      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _exercise = exercise;
        _contentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _contentLoading = false);
    }
  }

  void _openLesson() {
    final lesson = _lesson;
    if (lesson == null) return;
    context.showAppBottomSheet(
      child: AboutVideoPage(lesson: lesson, index: 0),
      backgroundColor: context.colors.white,
    );
  }

  void _openPayment() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PremiumSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                _Hero(remaining: _offerRemaining),
                const SizedBox(height: 20),
                _wrap(context, const _SocialProofRow()),
                const SizedBox(height: 28),
                _wrap(
                  context,
                  _LessonShowcase(
                    loading: _contentLoading,
                    lesson: _lesson,
                    onPlay: _openLesson,
                  ),
                ),
                const SizedBox(height: 28),
                _wrap(context, _JourneySection(journey: _journey)),
                const SizedBox(height: 28),
                _wrap(
                  context,
                  _ExerciseShowcase(
                    loading: _contentLoading,
                    exercise: _exercise,
                  ),
                ),
                const SizedBox(height: 28),
                _wrap(context, const _FeaturesSection()),
                const SizedBox(height: 28),
                _wrap(context, const _CompareSection()),
                const SizedBox(height: 28),
                _wrap(context, const _ValueStackCard()),
                const SizedBox(height: 28),
                _wrap(context, const _TestimonialsSection()),
                const SizedBox(height: 28),
                _wrap(context, const _FaqSection()),
                const SizedBox(height: 24),
                _wrap(
                  context,
                  _FinalReinforce(
                    remaining: _offerRemaining,
                    onBuy: _openPayment,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _BottomCta(onTap: _openPayment),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Hero header
// ─────────────────────────────────────────────────────────────────────────
class _Hero extends StatefulWidget {
  /// Shared countdown owned by the page, so this and the closing CTA stay
  /// in sync and restart on every open.
  final ValueListenable<Duration> remaining;
  const _Hero({required this.remaining});

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  /// Staggered fade + rise for a hero element, driven by [_intro].
  Widget _reveal(double start, double end, Widget child, {double dy = 22}) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * dy),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;
    final double w = MediaQuery.sizeOf(context).width;
    final double titleSize = w < 360 ? 23 : 27;
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.black, 0.30)!,
            accent,
            context.colors.accentLightSub,
          ],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Softly drifting glow orbs for depth.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, _) {
                  final t = _glow.value;
                  return Stack(
                    children: [
                      Positioned(
                        top: -60 + 14 * t,
                        right: -50,
                        child: _orb(
                            170,
                            context.colors.white
                                .withValues(alpha: 0.10 + 0.06 * t)),
                      ),
                      Positioned(
                        bottom: -70,
                        left: -40 - 14 * t,
                        child: _orb(
                            200,
                            context.colors.accentWhite
                                .withValues(alpha: 0.08 + 0.05 * (1 - t))),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
              child: _wrap(
                context,
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.router.maybePop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    context.colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: context.colors.white, size: 16),
                            ),
                          ),
                          const Spacer(),
                          _premiumBadge(context),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _reveal(
                        0.05,
                        0.55,
                        'pw_hero_title'
                            .tr()
                            .text(titleSize, titleSize + 6, 700)
                            .c(context.colors.white),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        0.15,
                        0.65,
                        'pw_hero_subtitle'
                            .tr()
                            .text(14, 20, 400)
                            .c(context.colors.white.withValues(alpha: 0.92)),
                      ),
                      const SizedBox(height: 16),
                      _reveal(
                        0.25,
                        0.75,
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (_) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(Icons.star_rounded,
                                    size: 16, color: context.colors.awayBase),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: 'pw_trust'
                                  .tr()
                                  .text(12, 16, 600)
                                  .c(context.colors.white)
                                  .copyWith(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _reveal(
                        0.4,
                        1.0,
                        _offerCard(context, accent),
                        dy: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PREMIUM pill with a gentle breathing pulse.
  Widget _premiumBadge(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.04 * _glow.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: context.colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.icons.crown.svg(
              width: 14,
              height: 14,
              colorFilter:
                  ColorFilter.mode(context.colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            'pw_hero_badge'.tr().text(11, 12, 700).c(context.colors.white),
          ],
        ),
      ),
    );
  }

  /// Glassy "-50%" card with a live mm:ss countdown.
  Widget _offerCard(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                '−50%'.text(20, 22, 800).c(accent),
                'pw_off'.tr().text(9, 10, 700).c(context.colors.textSub),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Assets.icons.fire.svg(width: 14, height: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: 'pw_offer_ends'
                          .tr()
                          .text(12, 15, 700)
                          .c(context.colors.white)
                          .copyWith(
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Duration>(
                  valueListenable: widget.remaining,
                  builder: (context, rem, _) => _CountdownTimer(
                    remaining: rem,
                    urgent: rem <= const Duration(minutes: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Shared mm:ss countdown display with rolling digit cells.
//  Stateless — the parent owns the ticking [remaining] value.
// ─────────────────────────────────────────────────────────────────────────
class _CountdownTimer extends StatelessWidget {
  final Duration remaining;
  final bool urgent;
  final double boxWidth;
  final double fontSize;

  const _CountdownTimer({
    required this.remaining,
    this.urgent = false,
    this.boxWidth = 36,
    this.fontSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(context, mm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            ':',
            style: TextStyle(
              color: context.colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _box(context, ss),
      ],
    );
  }

  Widget _box(BuildContext context, String value) {
    return Container(
      width: boxWidth,
      height: boxWidth + 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: urgent
            ? context.colors.errorBase.withValues(alpha: 0.9)
            : context.colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.white.withValues(alpha: 0.2)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.7),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
        ),
        child: Text(
          value,
          key: ValueKey(value),
          style: TextStyle(
            color: context.colors.white,
            fontSize: fontSize,
            height: (fontSize + 1) / fontSize,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Your journey — three phases + projection chart under one heading
// ─────────────────────────────────────────────────────────────────────────
class _JourneySection extends StatelessWidget {
  final _Journey journey;
  const _JourneySection({required this.journey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('pw_journey_title'.tr(),
            subtitle: 'pw_journey_subtitle'.tr()),
        const SizedBox(height: 16),
        const _PhasesCard(),
        const SizedBox(height: 12),
        _ProjectionChartCard(journey: journey),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  90-day journey framed as three momentum-building phases (not A→B).
// ─────────────────────────────────────────────────────────────────────────
class _PhasesCard extends StatelessWidget {
  const _PhasesCard();

  @override
  Widget build(BuildContext context) {
    final phases = <_Phase>[
      _Phase(Icons.eco_rounded, 'pw_phase_1_range'.tr(),
          'pw_phase_1_title'.tr(), 'pw_phase_1_desc'.tr()),
      _Phase(Icons.bolt_rounded, 'pw_phase_2_range'.tr(),
          'pw_phase_2_title'.tr(), 'pw_phase_2_desc'.tr()),
      _Phase(Icons.emoji_events_rounded, 'pw_phase_3_range'.tr(),
          'pw_phase_3_title'.tr(), 'pw_phase_3_desc'.tr()),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < phases.length; i++)
            _row(context, phases[i], isLast: i == phases.length - 1),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _Phase p, {required bool isLast}) {
    final accent = context.colors.accentSub;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, context.colors.accentLightSub],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(p.icon, size: 20, color: context.colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: context.colors.strokeSub),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: p.title
                            .text(15, 19, 700)
                            .c(context.colors.textStrong)
                            .copyWith(
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.colors.lightGreen,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: p.range.text(10, 13, 600).c(accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  p.desc.text(12, 17, 400).c(context.colors.textSub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Phase {
  final IconData icon;
  final String range;
  final String title;
  final String desc;
  _Phase(this.icon, this.range, this.title, this.desc);
}

// ─────────────────────────────────────────────────────────────────────────
//  Projection chart
// ─────────────────────────────────────────────────────────────────────────
class _ProjectionChartCard extends StatelessWidget {
  final _Journey journey;
  const _ProjectionChartCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;
    final grey = context.colors.iconSoft;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'pw_chart_title'.tr().text(16, 20, 700).c(context.colors.textStrong),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _legend(context, accent, 'pw_with_calora'.tr()),
              _legend(context, grey, 'pw_without_calora'.tr()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) =>
                  LineChart(_chartData(context, t, accent, grey)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: context.colors.textSub),
              const SizedBox(width: 6),
              Expanded(
                child: 'pw_chart_note'
                    .tr()
                    .text(11, 15, 400)
                    .c(context.colors.textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        label.text(12, 14, 500).c(context.colors.textSub),
      ],
    );
  }

  LineChartData _chartData(
      BuildContext context, double t, Color accent, Color grey) {
    final withSpots = <FlSpot>[];
    final withoutSpots = <FlSpot>[];
    final start = journey.startWeight;
    for (int w = 0; w <= 12; w++) {
      final f = w / 12;
      final withY = start + journey.delta * _easeOutCubic(f) * t;
      final withoutY = start + journey.delta * 0.18 * f * t;
      withSpots.add(FlSpot(w.toDouble(), withY));
      withoutSpots.add(FlSpot(w.toDouble(), withoutY));
    }

    final all = [...withSpots, ...withoutSpots].map((e) => e.y);
    final rawMin = all.reduce(math.min);
    final rawMax = all.reduce(math.max);
    final minY = rawMin - 2;
    final maxY = rawMax + 2;
    final interval = ((maxY - minY) / 3).clamp(1.0, double.infinity);

    return LineChartData(
      minX: 0,
      maxX: 12,
      minY: minY,
      maxY: maxY,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => FlLine(
            color: context.colors.strokeSoft, strokeWidth: 1, dashArray: [4, 4]),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 3,
            getTitlesWidget: (value, meta) {
              if (value % 3 != 0) return const SizedBox.shrink();
              final wk = value.toInt();
              final label =
                  wk == 0 ? 'pw_point_a'.tr() : '$wk ${'pw_week'.tr()}';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: label.text(9, 10, 500).c(context.colors.textSub),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: withoutSpots,
          isCurved: true,
          color: grey,
          barWidth: 2.5,
          dashArray: [5, 4],
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: withSpots,
          isCurved: true,
          color: accent,
          barWidth: 3.5,
          dotData: FlDotData(
            checkToShowDot: (spot, _) => spot.x == 0 || spot.x == 12,
            getDotPainter: (spot, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: accent,
              strokeWidth: 2,
              strokeColor: context.colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.28),
                accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _easeOutCubic(double x) => 1 - math.pow(1 - x, 3).toDouble();
}

// ─────────────────────────────────────────────────────────────────────────
//  Value stack — price anchoring
// ─────────────────────────────────────────────────────────────────────────
class _ValueStackCard extends StatelessWidget {
  const _ValueStackCard();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['pw_vs_nutritionist'.tr(), 'pw_vs_nutritionist_p'.tr()],
      ['pw_vs_trainer'.tr(), 'pw_vs_trainer_p'.tr()],
      ['pw_vs_courses'.tr(), 'pw_vs_courses_p'.tr()],
      ['pw_vs_apps'.tr(), 'pw_vs_apps_p'.tr()],
    ];
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'pw_vs_title'.tr().text(17, 22, 700).c(context.colors.textStrong),
          const SizedBox(height: 14),
          for (final r in rows) ...[
            Row(
              children: [
                Icon(Icons.remove_circle_outline_rounded,
                    size: 16, color: context.colors.iconSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: r[0]
                      .text(13, 18, 500)
                      .c(context.colors.textStrong)
                      .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _struck(context, "${r[1]} so'm"),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Divider(color: context.colors.strokeSoft, height: 20),
          Row(
            children: [
              Expanded(
                child: 'pw_vs_total'
                    .tr()
                    .text(13, 18, 600)
                    .c(context.colors.textSub)
                    .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                'pw_vs_total_p'.tr(),
                style: TextStyle(
                  color: context.colors.textSub,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 22, color: context.colors.accentSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      'pw_vs_calora'
                          .tr()
                          .text(14, 18, 700)
                          .c(context.colors.textStrong),
                      const SizedBox(height: 2),
                      'pw_vs_coffee'
                          .tr()
                          .text(12, 16, 500)
                          .c(context.colors.accentSub),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _struck(BuildContext context, String value) {
    return Text(
      value,
      style: TextStyle(
        color: context.colors.textSub,
        decoration: TextDecoration.lineThrough,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Social proof
// ─────────────────────────────────────────────────────────────────────────
class _SocialProofRow extends StatelessWidget {
  const _SocialProofRow();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Proof('94%', 'pw_proof_success'.tr(), context.colors.accentSub),
      _Proof('−8.4', 'pw_proof_loss'.tr(), context.colors.blueAccent),
      _Proof('4.9★', 'pw_proof_rating'.tr(), context.colors.warningBase),
      _Proof('50k+', 'pw_proof_users'.tr(), context.colors.accentSub),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: _tile(context, tiles[i])),
          if (i != tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, _Proof p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: p.value.text(17, 21, 700).c(p.color),
          ),
          const SizedBox(height: 4),
          p.label
              .text(9, 12, 500)
              .c(context.colors.textSub)
              .copyWith(textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}

class _Proof {
  final String value;
  final String label;
  final Color color;
  _Proof(this.value, this.label, this.color);
}

// ─────────────────────────────────────────────────────────────────────────
//  Compare: without vs with Calora
// ─────────────────────────────────────────────────────────────────────────
class _CompareSection extends StatelessWidget {
  const _CompareSection();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['pw_cmp_1'.tr(), 'pw_cmp_1b'.tr()],
      ['pw_cmp_2'.tr(), 'pw_cmp_2b'.tr()],
      ['pw_cmp_3'.tr(), 'pw_cmp_3b'.tr()],
      ['pw_cmp_4'.tr(), 'pw_cmp_4b'.tr()],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('pw_compare_title'.tr(),
            subtitle: 'pw_compare_subtitle'.tr()),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.strokeSoft),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: 'pw_compare_col_without'
                          .tr()
                          .text(13, 16, 600)
                          .c(context.colors.textSub)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                  ),
                  Container(
                      width: 1, height: 44, color: context.colors.strokeSoft),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.lightGreen,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(19)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Assets.icons.crown.svg(
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(
                                context.colors.accentSub, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: 'pw_compare_col_with'
                                .tr()
                                .text(13, 16, 700)
                                .c(context.colors.accentSub)
                                .copyWith(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              for (final r in rows)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: context.colors.strokeSoft)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _cell(context, r[0], false)),
                        Container(width: 1, color: context.colors.strokeSoft),
                        Expanded(
                          child: ColoredBox(
                            color: context.colors.lightGreen
                                .withValues(alpha: 0.4),
                            child: _cell(context, r[1], true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                context.colors.accentSub,
                context.colors.accentLightSub,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.accentSub.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: context.colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: 'pw_compare_footer'
                    .tr()
                    .text(13, 18, 700)
                    .c(context.colors.white)
                    .copyWith(maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, String text, bool good) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(good ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: good ? context.colors.accentSub : context.colors.iconSoft),
          const SizedBox(width: 8),
          Expanded(
            child: text.text(12, 16, good ? 600 : 400).c(
                good ? context.colors.textStrong : context.colors.textSub),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Features
// ─────────────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = <List<dynamic>>[
      [Strings.aiHealthAnalysisTitle, Strings.aiHealthAnalysisSubtitle, Assets.icons.brain],
      [Strings.aiFoodPhotoAnalysisTitle, Strings.aiFoodPhotoAnalysisSubtitle, Assets.icons.camera],
      [Strings.voiceFoodInputTitle, Strings.voiceFoodInputSubtitle, Assets.icons.icMicro],
      [Strings.men30DayWorkoutTitle, Strings.men30DayWorkoutSubtitle, Assets.icons.malePerson],
      [Strings.women30DayWorkoutTitle, Strings.women30DayWorkoutSubtitle, Assets.icons.femalePerson],
      [Strings.adFreeExperienceTitle, Strings.adFreeExperienceSubtitle, Assets.icons.shield],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('pw_features_title'.tr()),
        const SizedBox(height: 16),
        for (int i = 0; i < features.length; i++) ...[
          _FeatureCard(
            title: features[i][0] as String,
            description: features[i][1] as String,
            icon: features[i][2] as SvgGenImage,
          ),
          if (i != features.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final SvgGenImage icon;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colors.backgroundElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: icon.svg(
              height: 20,
              width: 20,
              colorFilter:
                  ColorFilter.mode(context.colors.accentSub, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title
                    .text(15, 20, 600)
                    .c(context.colors.textStrong)
                    .copyWith(maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                description
                    .text(13, 17, 400)
                    .c(context.colors.textSub)
                    .copyWith(maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded,
              size: 20, color: context.colors.accentSub),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Testimonials (verified, real-sounding)
// ─────────────────────────────────────────────────────────────────────────
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    final data = [
      _Testimonial('pw_tst_1_name'.tr(), 'pw_tst_1_text'.tr(),
          'pw_tst_1_result'.tr(), 'pw_tst_1_meta'.tr()),
      _Testimonial('pw_tst_2_name'.tr(), 'pw_tst_2_text'.tr(),
          'pw_tst_2_result'.tr(), 'pw_tst_2_meta'.tr()),
      _Testimonial('pw_tst_3_name'.tr(), 'pw_tst_3_text'.tr(),
          'pw_tst_3_result'.tr(), 'pw_tst_3_meta'.tr()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('pw_testimonials_title'.tr()),
        const SizedBox(height: 16),
        for (int i = 0; i < data.length; i++) ...[
          _card(context, _content(context, data[i])),
          if (i != data.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _content(BuildContext context, _Testimonial t) {
    final initial = t.name.trim().isEmpty ? '•' : t.name.trim()[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: context.colors.accentGreenWhite,
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: initial.text(18, 20, 700).c(context.colors.accentSub),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: t.name
                            .text(14, 18, 600)
                            .c(context.colors.textStrong)
                            .copyWith(
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded,
                          size: 14, color: context.colors.blueAccent),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      5,
                      (_) => Icon(Icons.star_rounded,
                          size: 13, color: context.colors.awayBase),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: context.colors.lightGreen,
                  borderRadius: BorderRadius.circular(100)),
              child: t.result.text(13, 16, 700).c(context.colors.accentSub),
            ),
          ],
        ),
        const SizedBox(height: 12),
        t.text.text(13, 19, 400).c(context.colors.textStrong),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 12, color: context.colors.textSub),
            const SizedBox(width: 4),
            Expanded(
              child: t.meta
                  .text(11, 14, 400)
                  .c(context.colors.textSub)
                  .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
    );
  }
}

class _Testimonial {
  final String name;
  final String text;
  final String result;
  final String meta;
  _Testimonial(this.name, this.text, this.result, this.meta);
}

// ─────────────────────────────────────────────────────────────────────────
//  FAQ
// ─────────────────────────────────────────────────────────────────────────
class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ['pw_faq_2_q'.tr(), 'pw_faq_2_a'.tr()],
      ['pw_faq_3_q'.tr(), 'pw_faq_3_a'.tr()],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('pw_faq_title'.tr()),
        const SizedBox(height: 16),
        for (int i = 0; i < faqs.length; i++) ...[
          _item(context, faqs[i][0], faqs[i][1]),
          if (i != faqs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _item(BuildContext context, String q, String a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: context.colors.accentSub),
              const SizedBox(width: 8),
              Expanded(
                  child: q.text(14, 18, 600).c(context.colors.textStrong)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: a.text(13, 18, 400).c(context.colors.textSub),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Final reinforcement
// ─────────────────────────────────────────────────────────────────────────
class _FinalReinforce extends StatefulWidget {
  /// Shared countdown owned by the page (kept in sync with the hero).
  final ValueListenable<Duration> remaining;

  /// Opens the payment sheet — the closing card is itself a CTA.
  final VoidCallback onBuy;

  const _FinalReinforce({required this.remaining, required this.onBuy});

  @override
  State<_FinalReinforce> createState() => _FinalReinforceState();
}

class _FinalReinforceState extends State<_FinalReinforce>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  Widget _reveal(double start, double end, Widget child, {double dy = 20}) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * dy),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;
    const radius = BorderRadius.all(Radius.circular(26));

    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final pop = Curves.easeOutBack.transform(
          CurvedAnimation(parent: _intro, curve: const Interval(0, 0.6)).value,
        );
        final fade = CurvedAnimation(
          parent: _intro,
          curve: const Interval(0, 0.5),
        ).value;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.94 + 0.06 * pop, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(accent, Colors.black, 0.28)!,
              accent,
              context.colors.accentLightSub,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.40),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) {
                    final t = _glow.value;
                    return Stack(
                      children: [
                        Positioned(
                          top: -50 + 12 * t,
                          right: -40,
                          child: _orb(
                              150,
                              context.colors.white
                                  .withValues(alpha: 0.12 + 0.06 * t)),
                        ),
                        Positioned(
                          bottom: -60,
                          left: -30 - 12 * t,
                          child: _orb(
                              180,
                              context.colors.accentWhite
                                  .withValues(alpha: 0.10 + 0.05 * (1 - t))),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                child: Column(
                  children: [
                    _reveal(0.0, 0.5, _medallion(context)),
                    const SizedBox(height: 16),
                    _reveal(
                      0.1,
                      0.6,
                      'pw_final_title'
                          .tr()
                          .text(20, 26, 800)
                          .c(context.colors.white)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    _reveal(0.2, 0.7, _joinRow(context)),
                    const SizedBox(height: 18),
                    _reveal(0.3, 0.85, _spotsLeft(context)),
                    const SizedBox(height: 16),
                    _reveal(0.4, 0.95, _timerBlock(context), dy: 26),
                    const SizedBox(height: 18),
                    _reveal(0.5, 1.0, _ctaButton(context), dy: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pulsing crown medallion.
  Widget _medallion(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) =>
          Transform.scale(scale: 1 + 0.06 * _glow.value, child: child),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.white.withValues(alpha: 0.18),
          border: Border.all(
              color: context.colors.white.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Center(
          child: Assets.icons.crown.svg(
            width: 28,
            height: 28,
            colorFilter:
                ColorFilter.mode(context.colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  /// Overlapping avatar stack + "join 50,000+" line.
  Widget _joinRow(BuildContext context) {
    const avatarCount = 4;
    const double d = 30;
    const double overlap = 20;
    final tints = [
      context.colors.accentLightSub,
      context.colors.blueAccent,
      context.colors.warningBase,
      context.colors.accentSoft,
    ];
    return Column(
      children: [
        SizedBox(
          height: d,
          width: overlap * (avatarCount - 1) + d + 8,
          child: Stack(
            children: [
              for (int i = 0; i < avatarCount; i++)
                Positioned(
                  left: i * overlap,
                  child: Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tints[i],
                      border: Border.all(color: context.colors.white, width: 2),
                    ),
                    child: Icon(Icons.person_rounded,
                        size: 16, color: context.colors.white),
                  ),
                ),
              Positioned(
                left: avatarCount * overlap,
                child: Container(
                  width: d,
                  height: d,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.white,
                    border: Border.all(color: context.colors.white, width: 2),
                  ),
                  child: '+'.text(16, 18, 800).c(context.colors.accentSub),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        'pw_join'
            .tr()
            .text(14, 19, 600)
            .c(context.colors.white)
            .copyWith(textAlign: TextAlign.center, maxLines: 2),
      ],
    );
  }

  /// Scarcity chip with an animated "almost full" progress bar.
  Widget _spotsLeft(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 15, color: context.colors.awayBase),
              const SizedBox(width: 6),
              Expanded(
                child: 'pw_spots_left'
                    .tr()
                    .text(12, 16, 600)
                    .c(context.colors.white)
                    .copyWith(maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: context.colors.white.withValues(alpha: 0.22),
                ),
                AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) => FractionallySizedBox(
                    widthFactor: 0.88 * _intro.value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(colors: [
                          context.colors.awayBase,
                          context.colors.warningBase,
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "50% off ends in" label + live mm:ss countdown.
  Widget _timerBlock(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.icons.fire.svg(width: 14, height: 14),
            const SizedBox(width: 6),
            Flexible(
              child: 'pw_offer_ends'
                  .tr()
                  .text(12, 16, 700)
                  .c(context.colors.white)
                  .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<Duration>(
          valueListenable: widget.remaining,
          builder: (context, rem, _) => _CountdownTimer(
            remaining: rem,
            urgent: rem <= const Duration(minutes: 1),
            boxWidth: 42,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  /// High-contrast white "buy now" button — the closing conversion point.
  Widget _ctaButton(BuildContext context) {
    final accent = context.colors.accentSub;
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.02 * _glow.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onBuy,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.crown.svg(
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: 'pw_final_cta'
                    .tr()
                    .text(16, 20, 800)
                    .c(accent)
                    .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Sticky bottom CTA (pinned below the scroll — always visible)
// ─────────────────────────────────────────────────────────────────────────
class _BottomCta extends StatelessWidget {
  final VoidCallback onTap;
  const _BottomCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.white,
      elevation: 16,
      shadowColor: context.colors.black.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12, top: 12),
        child: _wrap(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 14, color: context.colors.warningBase),
                  const SizedBox(width: 6),
                  Flexible(
                    child: 'pw_spots_left'
                        .tr()
                        .text(11, 14, 500)
                        .c(context.colors.warningBase)
                        .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        context.colors.accentSub,
                        Color.lerp(
                            context.colors.accentSub, Colors.black, 0.14)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.accentSub.withValues(alpha: 0.34),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Assets.icons.crown.svg(
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                            context.colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: 'pw_cta_button'
                            .tr()
                            .text(16, 20, 700)
                            .c(context.colors.white)
                            .copyWith(
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              'pw_guarantee'
                  .tr()
                  .text(11, 14, 400)
                  .c(context.colors.textSub)
                  .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Free video lesson — real, gender-aware content from the app
// ─────────────────────────────────────────────────────────────────────────
Widget _forYouChip(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: context.colors.accentGreenWhite,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_rounded, size: 12, color: context.colors.accentSub),
        const SizedBox(width: 4),
        'pw_for_you'.tr().text(10, 12, 600).c(context.colors.accentSub),
      ],
    ),
  );
}

Widget _mediaBadge(BuildContext context, IconData icon, String text, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: context.colors.white),
        const SizedBox(width: 4),
        text.text(9, 12, 700).c(context.colors.white),
      ],
    ),
  );
}

class _LessonShowcase extends StatelessWidget {
  final bool loading;
  final LessonRequest? lesson;
  final VoidCallback onPlay;

  const _LessonShowcase({
    required this.loading,
    required this.lesson,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionTitle('pw_video_title'.tr(),
                  subtitle: 'pw_video_subtitle'.tr()),
            ),
            const SizedBox(width: 8),
            _forYouChip(context),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const ShimmerChild(height: 230, radius: 22, width: double.infinity)
        else
          _card(context),
      ],
    );
  }

  Widget _card(BuildContext context) {
    final l = lesson;
    final cover = l?.coverImageUrl;
    final video = l?.videoUrl;
    final hasVideo = video != null && video.isNotEmpty;
    return GestureDetector(
      onTap: l == null ? null : onPlay,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: context.colors.accentSub.withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Live, muted, looping preview — the mentor speaking acts as
                // the "thumbnail". Falls back to the cover image, then a
                // bundled asset when no video is available.
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: hasVideo
                      ? LoopingMutedVideoPlayer(
                          url: video,
                          height: 200,
                          borderRadius: 0,
                        )
                      : (cover != null && cover.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: cover,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                  color: context.colors.backgroundElevation),
                              errorWidget: (_, __, ___) => Assets
                                  .images.courseImage
                                  .image(fit: BoxFit.cover),
                            )
                          : Assets.images.courseImage.image(fit: BoxFit.cover),
                ),
                // Soft top + bottom vignette so the badges stay legible over
                // any frame of the video without darkening the whole preview.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.28),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _mediaBadge(context, Icons.lock_open_rounded,
                      'pw_lesson_free'.tr(), context.colors.accentSub),
                ),
                if (l != null && l.duration.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          l.duration.text(11, 14, 600).c(context.colors.white),
                    ),
                  ),
                // Muted-preview hint — tap opens the full lesson with sound.
                if (hasVideo)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_off_rounded,
                              size: 12, color: context.colors.white),
                          const SizedBox(width: 5),
                          'pw_tap_sound'
                              .tr()
                              .text(10, 12, 600)
                              .c(context.colors.white),
                        ],
                      ),
                    ),
                  ),
                // Translucent play affordance — signals the preview is
                // tappable to watch full-screen with sound.
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          size: 32, color: context.colors.accentSub),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (l?.title.isNotEmpty == true
                                ? l!.title
                                : 'pw_video_title'.tr())
                            .text(15, 20, 700)
                            .c(context.colors.textStrong)
                            .copyWith(
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        'pw_video_subtitle'
                            .tr()
                            .text(12, 16, 400)
                            .c(context.colors.textSub)
                            .copyWith(
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill_rounded,
                            size: 16, color: context.colors.accentSub),
                        const SizedBox(width: 6),
                        'pw_video_watch'
                            .tr()
                            .text(12, 16, 700)
                            .c(context.colors.accentSub),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Graphic exercise — real, gender-aware animated content from the app
// ─────────────────────────────────────────────────────────────────────────
class _ExerciseShowcase extends StatelessWidget {
  final bool loading;
  final ExercisesRequest? exercise;

  const _ExerciseShowcase({required this.loading, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionTitle('pw_workout_title'.tr(),
                  subtitle: 'pw_workout_subtitle'.tr()),
            ),
            const SizedBox(width: 8),
            _forYouChip(context),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const ShimmerChild(height: 240, radius: 20, width: double.infinity)
        else
          _card(context),
      ],
    );
  }

  Widget _card(BuildContext context) {
    final ex = exercise;
    final preview = ex?.previewAssetUrl;
    final badge = ex?.computation?.format(
      durationUnit: 'pw_dur_unit'.tr(),
      countUnit: 'pw_count_unit'.tr(),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.strokeSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              (preview != null && preview.isNotEmpty)
                  ? AnimatedAssetView(url: preview, height: 210, borderRadius: 0)
                  : SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: Assets.images.day30WeightLossWorkout
                          .image(fit: BoxFit.cover),
                    ),
              Positioned(
                top: 12,
                left: 12,
                child: _mediaBadge(context, Icons.lock_open_rounded,
                    'pw_exercise_free'.tr(), context.colors.accentSub),
              ),
              if (badge != null && badge.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 12, color: context.colors.white),
                        const SizedBox(width: 4),
                        badge.text(11, 14, 600).c(context.colors.white),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      size: 20, color: context.colors.accentSub),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (ex?.title.isNotEmpty == true
                              ? ex!.title
                              : 'pw_workout_title'.tr())
                          .text(15, 20, 700)
                          .c(context.colors.textStrong)
                          .copyWith(
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      'pw_workout_subtitle'
                          .tr()
                          .text(12, 16, 400)
                          .c(context.colors.textSub)
                          .copyWith(
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title.text(20, 26, 700).c(context.colors.textStrong),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          subtitle!.text(13, 18, 400).c(context.colors.textSub),
        ],
      ],
    );
  }
}

Widget _card(BuildContext context, Widget child) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.colors.strokeSoft),
      boxShadow: [
        BoxShadow(
          color: context.colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────
//  Journey model (personalised from the user's profile)
// ─────────────────────────────────────────────────────────────────────────
class _Journey {
  final double startWeight;
  final double targetWeight;

  const _Journey({required this.startWeight, required this.targetWeight});

  factory _Journey.fallback() =>
      const _Journey(startWeight: 82, targetWeight: 72);

  factory _Journey.fromProfile(ProfileRequest p) {
    double start = (p.weight ?? p.entryWeight ?? 82).toDouble();
    double target = (p.targetWeight ?? 0).toDouble();

    final goal = (p.goal ?? '').toLowerCase();
    final isGain = goal.contains('mass') ||
        goal.contains('muscle') ||
        goal.contains('gain');

    if (target <= 0) {
      target = isGain ? start + 8 : start - 8;
    }
    if (start <= 0) start = isGain ? target - 8 : target + 8;

    return _Journey(startWeight: start, targetWeight: target);
  }

  double get delta => targetWeight - startWeight;
}
