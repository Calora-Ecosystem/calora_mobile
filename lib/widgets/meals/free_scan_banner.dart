import 'package:calora/common/di/injection.dart';
import 'package:calora/common/base/base_store.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/service/ai_quota_service.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Slim banner above the add-food actions for non-premium users. Shows how many
/// free AI recognitions (photo scan + voice, one shared pool) are left and,
/// once they run out, turns into a soft Premium upsell. Reads
/// [CommonStore.freeAiScansUsed] reactively so the number drops after a
/// successful scan or voice add.
class FreeScanBanner extends StatefulWidget {
  const FreeScanBanner({super.key, required this.onTap});

  /// Opens the paywall (upsell CTA / when credits run out).
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
            final remaining = limit - used;
            return remaining <= 0
                ? _buildExhausted(context)
                : _buildActive(context, remaining, limit);
          },
        );
      },
    );
  }

  Widget _buildActive(BuildContext context, int remaining, int limit) {
    final colors = context.colors;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.honeydew,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.paleGreen.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Assets.images.caloraLogo.image(
                  height: 20,
                  color: colors.mintGreen,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: 'free_scans_title'
                            .tr()
                            .text(13, 16, 700)
                            .c(colors.textStrong),
                      ),
                      '$remaining/$limit'.text(13, 16, 700).c(colors.mintGreen),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _segments(context, remaining, limit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One pill per free scan; the first [remaining] are lit — a glance shows how many are
  /// left without reading a number.
  Widget _segments(BuildContext context, int remaining, int limit) {
    final colors = context.colors;
    return Row(
      children: List.generate(limit, (i) {
        final lit = i < remaining;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == limit - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: lit ? colors.mintGreen : colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExhausted(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            center: const Alignment(1.4, -0.6),
            radius: 1.8,
            colors: [colors.honeydew, colors.mintGreen],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Row(
          children: [
            Assets.icons.crown.svg(
              height: 18,
              colorFilter: ColorFilter.mode(colors.textWhite, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: 'free_scans_over'
                  .tr()
                  .text(13, 16, 600)
                  .c(colors.textWhite),
            ),
            'unlimited_with_premium'.tr().text(12, 14, 600).c(colors.textWhite),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: colors.textWhite,
            ),
          ],
        ),
      ),
    );
  }
}
