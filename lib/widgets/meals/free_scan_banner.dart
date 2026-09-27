import 'dart:math' as math;

import 'package:calora/common/base/base_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/service/ai_quota_service.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Card above the add-food actions for non-premium users: how many free
/// recognitions (photo scan + voice, one shared pool) are left, as a ring and
/// a sentence. When they run out it says so plainly and offers Premium —
/// adding food by hand stays free, so it never reads as a dead end.
///
/// Reads [CommonStore.freeAiScansUsed] reactively so the count drops right
/// after a successful scan or voice add.
class FreeScanBanner extends StatefulWidget {
  const FreeScanBanner({super.key, required this.onTap});

  /// Opens the paywall.
  final VoidCallback onTap;

  @override
  State<FreeScanBanner> createState() => _FreeScanBannerState();
}

class _FreeScanBannerState extends State<FreeScanBanner> {
  final _store = getIt<CommonStore>();

  @override
  void initState() {
    super.initState();
    // Sync the cached count with the server; the streams below pick it up.
    getIt<AiQuotaService>().refresh();
  }

  Stream<int> _watch(BaseStore<int> store) async* {
    yield await store();
    yield* store.watch();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _watch(_store.freeAiScanLimit),
      initialData: kFreeAiScanLimit,
      builder: (context, limitSnapshot) {
        final limit = limitSnapshot.data ?? kFreeAiScanLimit;
        return StreamBuilder<int>(
          stream: _watch(_store.freeAiScansUsed),
          initialData: 0,
          builder: (context, snapshot) {
            final used = (snapshot.data ?? 0).clamp(0, limit);
            return FreeScanCard(
              remaining: limit - used,
              limit: limit,
              onTap: widget.onTap,
            );
          },
        );
      },
    );
  }
}

/// The banner's look, separate from the store so it can be laid out on its own.
class FreeScanCard extends StatelessWidget {
  const FreeScanCard({
    super.key,
    required this.remaining,
    required this.limit,
    required this.onTap,
  });

  final int remaining;
  final int limit;
  final VoidCallback onTap;

  static const _amber = Color(0xFFE59A1F);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final over = remaining <= 0;
    final last = remaining == 1;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSoft),
        ),
        child: Row(
          children: [
            over
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 21,
                      color: _amber,
                    ),
                  )
                : _Ring(
                    value: remaining,
                    limit: limit,
                    color: last ? _amber : colors.accentSub,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (over
                          ? 'free_scans_over'.tr()
                          : 'free_scans_left_title'.tr(
                              namedArgs: {'count': '$remaining'},
                            ))
                      .text(14, 19, 600)
                      .c(colors.textStrong),
                  const SizedBox(height: 2),
                  (over
                          ? 'free_scans_over_sub'
                          : last
                          ? 'free_scans_last_sub'
                          : 'free_scans_sub')
                      .tr()
                      .text(12, 16, 400)
                      .c(colors.textSub)
                      .copyWith(maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            over
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentSub,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: 'Premium'.text(13, 16, 600).c(colors.white),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: colors.iconSoft,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Remaining scans as a ring: the arc is what's left, the number sits inside.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.limit, required this.color});

  final int value;
  final int limit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = context.colors.softGray;
    return SizedBox(
      width: 44,
      height: 44,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: limit == 0 ? 0 : value / limit),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _RingPainter(progress: t, color: color, track: track),
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textStrong,
                    ),
                  ),
                  TextSpan(
                    text: '/$limit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSub,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontFamily: FontFamily.inter, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Shown when a non-premium user taps scan / voice with no free recognitions
/// left: explains what happened and offers Premium, with manual entry as the
/// free way to keep going.
class FreeScansOverSheet extends StatelessWidget {
  const FreeScansOverSheet({
    super.key,
    required this.limit,
    required this.onPremium,
  });

  final int limit;
  final VoidCallback onPremium;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const perks = [
      (Icons.photo_camera_outlined, 'free_over_perk_scan'),
      (Icons.mic_none_rounded, 'free_over_perk_voice'),
      (Icons.insights_rounded, 'free_over_perk_macros'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.accentGreenWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              color: colors.accentSub,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          'free_over_title'
              .tr(namedArgs: {'count': '$limit'})
              .text(20, 26, 700)
              .c(colors.textStrong),
          const SizedBox(height: 8),
          'free_over_body'.tr().text(14, 20, 400).c(colors.textSub),
          const SizedBox(height: 18),
          for (final (icon, key) in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colors.accentSub),
                  const SizedBox(width: 12),
                  Expanded(
                    child: key.tr().text(14, 19, 500).c(colors.textPrimary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPremium();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: 'free_over_cta'.tr().text(16, 20, 600).c(colors.white),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: 'free_over_manual'
                  .tr()
                  .text(14, 18, 500)
                  .c(colors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
