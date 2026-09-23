import 'dart:math' as math;

import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Wallet banner that explains how coins are earned — "1000 steps = 1 coin,
/// up to 22 a day" — and shows today's progress toward that daily limit.
///
/// A small scene plays on the right: a walker crosses the track, a "+1" coin
/// floats up from each stride and a coin spins above. It pauses (renders a
/// still frame) when the platform asks to reduce motion.
class StepCoinBanner extends StatefulWidget {
  const StepCoinBanner({
    super.key,
    required this.stepsPerCoin,
    required this.maxDailyCoins,
    required this.todayCoins,
  });

  final int stepsPerCoin;
  final int maxDailyCoins;
  final int todayCoins;

  @override
  State<StepCoinBanner> createState() => _StepCoinBannerState();
}

class _StepCoinBannerState extends State<StepCoinBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop
        ..stop()
        ..value = 0.55;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final max = widget.maxDailyCoins <= 0 ? 1 : widget.maxDailyCoins;
    final progress = (widget.todayCoins / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.mintGreen, colors.accentSub],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.mintGreen.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: 'coin_banner_chip'
                          .tr()
                          .text(11, 14, 700)
                          .c(colors.textWhite),
                    ),
                    const SizedBox(height: 10),
                    'coin_earn_rule'
                        .tr(namedArgs: {'steps': '${widget.stepsPerCoin}'})
                        .text(20, 25, 800)
                        .c(colors.textWhite),
                    const SizedBox(height: 4),
                    'coin_earn_limit'
                        .tr(namedArgs: {'coins': '${widget.maxDailyCoins}'})
                        .text(13, 17, 500)
                        .c(colors.textWhite.withValues(alpha: 0.9)),
                  ],
                ),
              ),
              SizedBox(
                width: 104,
                height: 96,
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) => _scene(context, _loop.value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              'coin_banner_today'
                  .tr()
                  .text(12, 15, 600)
                  .c(colors.textWhite.withValues(alpha: 0.9)),
              const Spacer(),
              '${widget.todayCoins}/${widget.maxDailyCoins}'
                  .text(13, 16, 800)
                  .c(colors.textWhite),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: colors.white.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(colors.textWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One frame of the scene at loop position [t] (0..1).
  Widget _scene(BuildContext context, double t) {
    final colors = context.colors;
    const trackWidth = 104.0;
    const walkerSize = 26.0;

    // Walker crosses the track, bobbing with each stride.
    final walkerX = (trackWidth - walkerSize) * t;
    final bob = math.sin(t * math.pi * 8).abs() * 3;

    // A "+1" pops out of each stride and floats up, fading.
    final pops = <Widget>[];
    for (final start in const [0.15, 0.5, 0.85]) {
      final local = ((t - start) % 1.0) / 0.35;
      if (local < 0 || local > 1) continue;
      final x = (trackWidth - walkerSize) * start + 2;
      pops.add(
        Positioned(
          left: x,
          bottom: 30 + local * 34,
          child: Opacity(
            opacity: (1 - local).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.8 + local * 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 11,
                      color: colors.accentSub,
                    ),
                    const SizedBox(width: 2),
                    '+1'.text(10, 12, 800).c(colors.accentSub),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The spinning coin in the corner.
    final spin = t * 2 * math.pi;
    final coinFloat = math.sin(t * 2 * math.pi) * 3;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 4,
          top: 0 + coinFloat,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(spin),
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.white,
                boxShadow: [
                  BoxShadow(
                    color: colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: colors.accentSub,
                size: 26,
              ),
            ),
          ),
        ),
        // Track.
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Row(
            children: List.generate(
              9,
              (i) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: colors.white.withValues(
                      alpha: i / 9 <= t ? 0.85 : 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        ...pops,
        Positioned(
          left: walkerX,
          bottom: 10 + bob,
          child: Icon(
            Icons.directions_walk_rounded,
            color: colors.textWhite,
            size: walkerSize,
          ),
        ),
      ],
    );
  }
}
