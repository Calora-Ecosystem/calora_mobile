import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_manager.dart';
import 'package:calora/presentation/questions/calculate_plane/widget/weight_progress_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CalculatePage
    extends Managed<CalculateManager, CalculateState, CalculateEffect> {
  final double startValue;
  final double endValue;
  const CalculatePage({
    super.key,
    required this.startValue,
    required this.endValue,
  });

  @override
  void init(BuildContext context, CalculateManager manager) {
    manager.getProfile();
    manager.getDailyGoals();
    super.init(context, manager);
  }

  @override
  listener(
    BuildContext context,
    CalculateManager manager,
    CalculateEffect effect,
  ) {
    effect.when(
      error: (String message) {},
      navigateNext: () => goToNextPage(context),
    );
  }

  @override
  Widget builder(
    BuildContext context,
    CalculateManager manager,
    CalculateState state,
  ) {
    if (state.isLoading || state.dailyGoals.isEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Assets.icons.background.image(fit: BoxFit.fill),
            ),
            Center(
              child: CircularProgressIndicator(color: context.colors.accentSub),
            ),
          ],
        ),
      );
    }

    // A goal is "loss" when the target is below the current weight.
    final bool isLoss = endValue < startValue;
    final double diff = (startValue - endValue).abs();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  // The plan-ready screen is a fixed, non-scrolling page — the
                  // content is sized to fit, so it must never drift up/down.
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FadeSlideIn(
                          child: _CelebrationHeader(),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlideIn(
                          delayMs: 90,
                          child: _WeightJourneyCard(
                            startValue: startValue,
                            endValue: endValue,
                            isLoss: isLoss,
                            diff: diff,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FadeSlideIn(
                          delayMs: 180,
                          child: 'cal_daily_targets'
                              .tr()
                              .text(18, 24, 700)
                              .c(context.colors.textStrong),
                        ),
                        const SizedBox(height: 12),
                        _FadeSlideIn(
                          delayMs: 240,
                          child: _DailyTargets(goals: state.dailyGoals),
                        ),
                      ],
                    ),
                  ),
                ),
                _FadeSlideIn(
                  delayMs: 300,
                  child: Padding(
                    // Transparent bar so the page's green background flows
                    // straight down behind the button — no white seam between
                    // the daily-targets area and the CTA.
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: Button(
                        onPressed: () => goToNextPage(context),
                        text: Strings.start,
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

  /// After the plan is confirmed we bring the user straight to the
  /// dashboard, but surface the premium paywall once on top of it. It is
  /// optional — closing it (back arrow) drops the user onto the dashboard
  /// that is already mounted underneath, and a successful purchase clears
  /// the paywall the same way.
  void goToNextPage(BuildContext context) {
    context.router.replaceAll([
      DashboardRoute(),
      const PremiumFeaturesRoute(),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Celebration header — success badge + title + personalized subtitle.
// ─────────────────────────────────────────────────────────────────────────
class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader();

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, context.colors.accentLightSub],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            color: context.colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        Strings.yourProgramIsReady
            .text(24, 30, 800)
            .c(context.colors.textStrong)
            .copyWith(textAlign: TextAlign.center),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Weight journey — Now → Target chips over the projection chart.
// ─────────────────────────────────────────────────────────────────────────
class _WeightJourneyCard extends StatelessWidget {
  final double startValue;
  final double endValue;
  final bool isLoss;
  final double diff;

  const _WeightJourneyCard({
    required this.startValue,
    required this.endValue,
    required this.isLoss,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.black.withValues(alpha: 0.03),
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
                child: 'cal_weight_journey'
                    .tr()
                    .text(16, 20, 700)
                    .c(context.colors.textStrong),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.colors.lightGreen,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLoss
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    '${diff.toInt()} ${'pw_weight_unit'.tr()}'
                        .text(12, 14, 700)
                        .c(accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // A → B endpoints, spelled out so the start (now) and goal (target)
          // read at a glance before the curve fills them in.
          Row(
            children: [
              Expanded(
                child: _endpoint(
                  context,
                  marker: 'A',
                  label: 'cal_now'.tr(),
                  value: startValue.toInt().toString(),
                  markerColor: context.colors.neutral600Secondary,
                  valueColor: context.colors.textStrong,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accentGreenWhite,
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _endpoint(
                  context,
                  marker: 'B',
                  label: 'cal_target'.tr(),
                  value: endValue.toInt().toString(),
                  markerColor: accent,
                  valueColor: accent,
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeightProgressChart(
            startValue: startValue,
            endValue: endValue,
            color: accent,
            height: 150,
          ),
        ],
      ),
    );
  }

  /// One end of the journey — an "A"/"B" marker, its label and the big weight.
  Widget _endpoint(
    BuildContext context, {
    required String marker,
    required String label,
    required String value,
    required Color markerColor,
    required Color valueColor,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? context.colors.lightGreen
            : context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: markerColor,
                ),
                child: marker.text(11, 13, 700).c(context.colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: label
                    .text(12, 14, 600)
                    .c(context.colors.textSub)
                    .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              value.text(26, 30, 800).c(valueColor),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: 'pw_weight_unit'
                    .tr()
                    .text(13, 16, 600)
                    .c(context.colors.textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Daily targets — calories / steps / water as three stat tiles.
// ─────────────────────────────────────────────────────────────────────────
class _DailyTargets extends StatelessWidget {
  final List<double> goals;
  const _DailyTargets({required this.goals});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _TargetTile(
        icon: Assets.icons.vegetarianFood.svg(),
        value: goals[0].toDouble().asFixedTruncated(0),
        unit: Strings.kcal,
        label: Strings.mealPlan,
        tint: context.colors.accentGreenWhite,
      ),
      _TargetTile(
        icon: Assets.icons.workoutSport.svg(),
        value: '${goals[1].toInt()}',
        unit: Strings.step,
        label: Strings.steps,
        tint: context.colors.progressBackground,
      ),
      _TargetTile(
        icon: Assets.icons.water.svg(),
        value: '${goals[2].toInt()}',
        unit: 'ml',
        label: Strings.water,
        tint: context.colors.informationLighter,
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i != tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TargetTile extends StatelessWidget {
  final Widget icon;
  final String value;
  final String unit;
  final String label;
  final Color tint;

  const _TargetTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
            child: SizedBox(width: 20, height: 20, child: icon),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: value.text(18, 22, 800).c(context.colors.textStrong),
          ),
          const SizedBox(height: 2),
          unit.text(11, 13, 500).c(context.colors.textSub),
          const SizedBox(height: 6),
          label
              .text(11, 14, 500)
              .c(context.colors.textSub)
              .copyWith(
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  One-shot fade + rise used to stagger the sections in on mount.
// ─────────────────────────────────────────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 20),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
