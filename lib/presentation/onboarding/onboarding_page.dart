import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _floatController;

  int _currentPage = 0;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _controller.page ?? 0;
    if (page != _page) setState(() => _page = page);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  List<_ObPage> _pages(BuildContext context) => [
    _ObPage(
      title: Strings.changingLifestyle,
      message: Strings.changingLifestyleDesc,
      tag: 'ob_tag_1'.tr(),
      image: Assets.icons.icOnboardingDrinkingBoy.image(),
      accent: context.colors.accentSub,
      accentSoft: context.colors.accentGreenWhite,
      chips: [
        _ObChip(Assets.icons.fire, '92%', 'ob_stat_1'.tr()),
        _ObChip(Assets.icons.energy, '+38%', 'ob_energy'.tr()),
      ],
    ),
    _ObPage(
      title: Strings.healthyEating,
      message: Strings.healthyEatingDesc,
      tag: 'ob_tag_2'.tr(),
      image: Assets.icons.icOnboardingPhone.image(),
      accent: context.colors.blueAccent,
      accentSoft: context.colors.informationLighter,
      chips: [
        _ObChip(Assets.icons.icCalorie, '1 850', 'ob_stat_2'.tr()),
        _ObChip(Assets.icons.camera, 'AI', Strings.aiFoodPhotoAnalysisTitle),
      ],
    ),
    _ObPage(
      title: Strings.enoughDay,
      message: Strings.enoughDayDesc,
      tag: 'ob_tag_3'.tr(),
      image: Assets.icons.icOnboardingEngagingBoy.image(),
      accent: context.colors.warningBase,
      accentSoft: context.colors.warningLighter,
      chips: [
        _ObChip(Assets.icons.stepsHuman, '10 000', 'ob_stat_3'.tr()),
        _ObChip(Assets.icons.goal, '7/7', Strings.goal),
      ],
    ),
    _ObPage(
      title: Strings.dailyWaterNorm,
      message: Strings.dailyWaterNormDesc,
      tag: 'ob_tag_4'.tr(),
      image: Assets.icons.icOnboardingWaterPhone.image(),
      accent: context.colors.informationBase,
      accentSoft: context.colors.progressBackground,
      chips: [
        _ObChip(Assets.icons.droplet, '8', 'ob_stat_4'.tr()),
        _ObChip(Assets.icons.water, '2.5L', Strings.dailyWaterNorm),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final int index = _page.round().clamp(0, pages.length - 1);
    final _ObPage active = pages[index];
    final bool isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: context.colors.white,
      body: Stack(
        children: [
          // ── Ambient animated background blobs (tinted by active page) ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [active.accentSoft, context.colors.white],
              ),
            ),
          ),
          _blob(context, top: -80, left: -60, color: active.accent, size: 260),
          _blob(
            context,
            top: 180,
            right: -90,
            color: active.accent,
            size: 200,
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Header: progress + skip ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProgressDots(
                          count: pages.length,
                          page: _page,
                          color: active.accent,
                          trackColor: context.colors.strokeSub,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _finish,
                        child: 'ob_skip'
                            .tr()
                            .text(14, 18, 500)
                            .c(context.colors.textSub),
                      ),
                    ],
                  ),
                ),
                // ── Swipeable scenes ──
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) {
                      final delta = (_page - i);
                      return _ObScene(
                        page: pages[i],
                        parallax: delta,
                        floatController: _floatController,
                      );
                    },
                  ),
                ),
                // ── CTA ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: _CtaButton(
                    label: isLast ? 'ob_start'.tr() : 'ob_next'.tr(),
                    color: active.accent,
                    onTap: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  void _finish() {
    getIt<CommonStore>().isOnboardingCompleted.set(true);
    context.router.replace(AuthRoute());
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Scene: floating hero card with parallax + orbiting stat chips
// ─────────────────────────────────────────────────────────────────────────
class _ObScene extends StatelessWidget {
  final _ObPage page;
  final double parallax;
  final AnimationController floatController;

  const _ObScene({
    required this.page,
    required this.parallax,
    required this.floatController,
  });

  @override
  Widget build(BuildContext context) {
    final double p = parallax.clamp(-1.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: floatController,
                builder: (context, child) {
                  final t = floatController.value * 2 * math.pi;
                  return Transform.translate(
                    offset: Offset(
                      -p * 46,
                      math.sin(t) * 8,
                    ),
                    child: Opacity(opacity: (1 - p.abs()).clamp(0.0, 1.0), child: child),
                  );
                },
                child: _HeroCard(page: page, floatController: floatController),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-p * 24, 0),
            child: Opacity(
              opacity: (1 - p.abs() * 1.3).clamp(0.0, 1.0),
              child: _SceneText(page: page),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final _ObPage page;
  final AnimationController floatController;

  const _HeroCard({required this.page, required this.floatController});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.86,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Concentric decorative rings
          _ring(1.0, page.accent.withValues(alpha: 0.10)),
          _ring(0.78, page.accent.withValues(alpha: 0.14)),
          // Main glass card
          Container(
            margin: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colors.white,
                  page.accentSoft,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.22),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: page.image,
              ),
            ),
          ),
          // Floating stat chips
          Positioned(
            top: 24,
            right: -4,
            child: _floatChip(context, page.chips[0], -1),
          ),
          Positioned(
            bottom: 44,
            left: -6,
            child: _floatChip(context, page.chips[1], 1),
          ),
        ],
      ),
    );
  }

  Widget _floatChip(BuildContext context, _ObChip chip, double phase) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        final t = floatController.value * 2 * math.pi + phase;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * 6),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: page.accentSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: chip.icon.svg(
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(page.accent, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                chip.value.text(14, 16, 700).c(context.colors.textStrong),
                chip.label
                    .text(10, 12, 500)
                    .c(context.colors.textSub)
                    .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double scale, Color color) {
    return FractionallySizedBox(
      widthFactor: scale,
      heightFactor: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
      ),
    );
  }
}

class _SceneText extends StatelessWidget {
  final _ObPage page;

  const _SceneText({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: page.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: page.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              page.tag.text(12, 14, 600).c(page.accent),
            ],
          ),
        ),
        const SizedBox(height: 16),
        page.title.text(28, 34, 700).c(context.colors.textStrong),
        const SizedBox(height: 12),
        page.message.text(15, 22, 400).c(context.colors.textSub),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Small building blocks
// ─────────────────────────────────────────────────────────────────────────
class _ProgressDots extends StatelessWidget {
  final int count;
  final double page;
  final Color color;
  final Color trackColor;

  const _ProgressDots({
    required this.count,
    required this.page,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = (1 - (page - i).abs()).clamp(0.0, 1.0);
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Color.lerp(trackColor, color, active),
            ),
          ),
        );
      }),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.14)!],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label.text(16, 20, 600).c(context.colors.white),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: context.colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Data holders
// ─────────────────────────────────────────────────────────────────────────
class _ObPage {
  final String title;
  final String message;
  final String tag;
  final Widget image;
  final Color accent;
  final Color accentSoft;
  final List<_ObChip> chips;

  _ObPage({
    required this.title,
    required this.message,
    required this.tag,
    required this.image,
    required this.accent,
    required this.accentSoft,
    required this.chips,
  });
}

class _ObChip {
  final SvgGenImage icon;
  final String value;
  final String label;

  _ObChip(this.icon, this.value, this.label);
}
