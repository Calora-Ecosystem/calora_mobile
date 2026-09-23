import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/repo/referral/referral_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/referral/referral_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shown once right after a new account is created, before the onboarding
/// questions: "did a friend invite you?". Confirming the friend's code tells
/// the server who brought this user in (the friend moves toward their free
/// Premium) and unlocks this user's first-purchase discount. Skippable — the
/// code can still be entered later from Profile → Invite friends.
@RoutePage()
class InviteCodePage extends StatefulWidget {
  const InviteCodePage({super.key});

  @override
  State<InviteCodePage> createState() => _InviteCodePageState();
}

class _InviteCodePageState extends State<InviteCodePage> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() => context.router.replace(QuestionsRoute());

  Future<void> _confirm() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await getIt<ReferralRepo>().apply(code);
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        'invite_code_applied'.tr(
          namedArgs: {
            'name': result.referrerName,
            'percent': '${result.discountPercent}',
          },
        ),
      );
      _continue();
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, referralErrorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.softGray,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : _continue,
                child: 'skip'.tr().text(15, 20, 600).c(colors.textSub),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Assets.images.premiumFire.image(height: 110)),
            const SizedBox(height: 20),
            'invite_code_title'
                .tr()
                .text(22, 28, 700)
                .c(colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 8),
            'invite_code_subtitle'
                .tr()
                .text(15, 20, 500)
                .c(colors.textSub)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 28),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: colors.textStrong,
              ),
              decoration: InputDecoration(
                hintText: 'CALORA-XXXX',
                filled: true,
                fillColor: colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.strokeSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.strokeSoft),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Button(
              text: 'confirm_action'.tr(),
              enabled: _controller.text.trim().isNotEmpty && !_loading,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
