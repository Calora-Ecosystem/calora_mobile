import 'dart:async';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/util/share_origin.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// App download link appended to the family invite.
const String _appLink = 'https://calora.uz/get-app?utm_source=family_plan';

/// Family plan: the code the buyer sends to the second person, ready to
/// copy or share. Opened right after the family plan is paid for, and from
/// Profile → Subscription so the code is never lost with a closed popup.
class FamilyCodeSheet extends StatefulWidget {
  /// Just paid: the backend issues the code when the payment is accepted,
  /// which can trail the app by a moment — poll briefly before giving up.
  final bool waitForNew;

  const FamilyCodeSheet({super.key, this.waitForNew = false});

  static Future<void> show(BuildContext context, {bool waitForNew = false}) =>
      context.showAppBottomSheet(
        child: FamilyCodeSheet(waitForNew: waitForNew),
      );

  @override
  State<FamilyCodeSheet> createState() => _FamilyCodeSheetState();
}

class _FamilyCodeSheetState extends State<FamilyCodeSheet> {
  static const _retries = 4;
  static const _retryDelay = Duration(seconds: 2);

  FamilyCode? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = getIt<PremiumRepo>();
    for (var attempt = 0; ; attempt++) {
      FamilyCode? code;
      try {
        code = _pick(await repo.getFamilyCodes());
      } catch (_) {
        // Shown as "being prepared" below; Profile → Subscription has it later.
      }
      final lastTry = !widget.waitForNew || attempt >= _retries;
      if (code != null || lastTry) {
        if (mounted) {
          setState(() {
            _code = code;
            _loading = false;
          });
        }
        return;
      }
      await Future<void>.delayed(_retryDelay);
      if (!mounted) return;
    }
  }

  /// The newest unused code; otherwise (when just looking it up) the newest
  /// one, so a redeemed or expired code still explains itself. Right after
  /// paying only a fresh, unused code counts.
  FamilyCode? _pick(List<FamilyCode> codes) {
    for (final code in codes) {
      if (code.status == FamilyCodeStatus.active) return code;
    }
    return codes.isNotEmpty && !widget.waitForNew ? codes.first : null;
  }

  void _copy() {
    final code = _code;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code.code));
    HapticFeedback.selectionClick();
    CustomSnackBar.showSuccess(context, 'copied'.tr());
  }

  Future<void> _share(BuildContext buttonContext) async {
    final code = _code;
    if (code == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'family_code_share_text'.tr(
            namedArgs: {
              'code': code.code,
              'months': '${code.months}',
              'link': _appLink,
            },
          ),
          sharePositionOrigin: shareOrigin(buttonContext),
        ),
      );
    } catch (_) {
      if (mounted) CustomSnackBar.show(context, 'something_went_wrong'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final code = _code;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          'family_code_title'.tr().text(20, 26, 700).c(colors.textStrong),
          const SizedBox(height: 6),
          'family_code_subtitle'
              .tr(namedArgs: {'months': '${code?.months ?? 1}'})
              .text(14, 20, 400)
              .c(colors.textSub),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (code == null)
            _pending(context)
          else ...[
            _codeBox(context, code),
            const SizedBox(height: 10),
            _status(context, code),
            if (code.status == FamilyCodeStatus.active) ...[
              const SizedBox(height: 20),
              Builder(
                builder: (buttonContext) => Button(
                  text: 'share'.tr(),
                  onPressed: () => _share(buttonContext),
                ),
              ),
              const SizedBox(height: 10),
              Button(
                text: 'family_code_copy'.tr(),
                type: ButtonType.secondary,
                onPressed: _copy,
              ),
              const SizedBox(height: 24),
              _steps(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _codeBox(BuildContext context, FamilyCode code) {
    final colors = context.colors;
    final active = code.status == FamilyCodeStatus.active;
    return GestureDetector(
      onTap: active ? _copy : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: active ? colors.honeydew : colors.backgroundElevation,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? colors.paleGreen : colors.strokeSoft,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                code.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: active ? colors.textStrong : colors.textSub,
                  // A redeemed code did its job; only an expired one is void.
                  decoration: code.status == FamilyCodeStatus.expired
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (active)
              Icon(Icons.copy_rounded, size: 20, color: colors.accentSub),
          ],
        ),
      ),
    );
  }

  Widget _status(BuildContext context, FamilyCode code) {
    final colors = context.colors;
    final (String text, Color color) = switch (code.status) {
      FamilyCodeStatus.active => (
        code.expireAt == null
            ? ''
            : 'family_code_active_until'.tr(
                namedArgs: {'date': _formatDate(code.expireAt!)},
              ),
        colors.textSub,
      ),
      FamilyCodeStatus.redeemed => (
        code.redeemedBy?.trim().isNotEmpty == true
            ? 'family_code_redeemed_by'.tr(
                namedArgs: {'name': code.redeemedBy!.trim()},
              )
            : 'family_code_redeemed'.tr(),
        colors.accentSub,
      ),
      FamilyCodeStatus.expired => ('family_code_expired'.tr(), colors.errorBase),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return text.text(13, 18, 500).c(color).copyWith(textAlign: TextAlign.center);
  }

  Widget _pending(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, size: 20, color: colors.textSub),
          const SizedBox(width: 10),
          Expanded(
            child: 'family_code_pending'
                .tr()
                .text(14, 20, 500)
                .c(colors.textStrong),
          ),
        ],
      ),
    );
  }

  /// The three steps the partner goes through — the same ones the shared
  /// message spells out.
  Widget _steps(BuildContext context) {
    final colors = context.colors;
    const steps = ['family_code_how_1', 'family_code_how_2', 'family_code_how_3'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        'tf_family_how'.tr().text(15, 20, 700).c(colors.textStrong),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 22,
                  width: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: '${i + 1}'.text(12, 14, 700).c(colors.accentSub),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: steps[i].tr().text(14, 20, 400).c(colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
