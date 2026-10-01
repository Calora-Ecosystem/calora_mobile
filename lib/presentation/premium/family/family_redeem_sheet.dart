import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/confetti/confetti.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/family/family_code_error.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Family plan, second person: enter the code the buyer sent and Premium
/// turns on right away.
class FamilyRedeemSheet extends StatefulWidget {
  const FamilyRedeemSheet({super.key});

  /// Opens the sheet; on success celebrates and, with [goHome], lands on the
  /// dashboard like a purchase does. Returns whether a code was redeemed.
  static Future<bool> show(BuildContext context, {bool goHome = true}) async {
    final result = await context.showAppBottomSheet<FamilyRedeemResult>(
      child: const FamilyRedeemSheet(),
    );
    if (result == null || !context.mounted) return false;
    await celebrate(context, result.ownerName, goHome: goHome);
    return true;
  }

  /// Confetti + "Premium is on" — shared with the promo-code field, which
  /// accepts family codes too.
  static Future<void> celebrate(
    BuildContext context,
    String? ownerName, {
    bool goHome = true,
  }) async {
    await PremiumConfettiOverlay.show(context);
    if (!context.mounted) return;
    final name = ownerName?.trim() ?? '';
    CustomSnackBar.showSuccess(
      context,
      name.isEmpty
          ? 'family_redeem_success_plain'.tr()
          : 'family_redeem_success'.tr(namedArgs: {'name': name}),
    );
    if (goHome) context.router.root.replaceAll([DashboardRoute()]);
  }

  @override
  State<FamilyRedeemSheet> createState() => _FamilyRedeemSheetState();
}

class _FamilyRedeemSheetState extends State<FamilyRedeemSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await getIt<PremiumRepo>().redeemFamilyCode(code);
      if (result.requiresTokenRefresh) {
        await getIt<TokenInterceptor>().refreshAndCheckPremium();
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = familyCodeErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canSubmit = _controller.text.trim().isNotEmpty && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          'family_redeem_action'.tr().text(20, 26, 700).c(colors.textStrong),
          const SizedBox(height: 6),
          'family_redeem_subtitle'.tr().text(14, 20, 400).c(colors.textSub),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _redeem(),
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colors.textStrong,
            ),
            decoration: InputDecoration(
              hintText: 'FAMILY-XXXXXX',
              hintStyle: TextStyle(
                color: colors.iconSoft,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: colors.backgroundElevation,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error == null ? colors.strokeSoft : colors.errorBase,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _error == null ? colors.accentSub : colors.errorBase,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _error!.text(13, 18, 500).c(colors.errorBase),
          ],
          const SizedBox(height: 20),
          Button(
            text: 'family_redeem_button'.tr(),
            enabled: canSubmit,
            loading: _busy,
            onPressed: _redeem,
          ),
        ],
      ),
    );
  }
}
