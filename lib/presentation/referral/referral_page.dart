import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/api_error_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/referral/referral_info.dart';
import 'package:calora/domain/repo/referral/referral_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Referral screen — share your code; every [ReferralInfo.friendsGoal] friends
/// who join with it and start using the app earn [ReferralInfo.premiumDays]
/// days of Premium. Friends who joined get a first-purchase discount.
/// Everything is read from `referrals/me` and `referrals/invited`.
class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage>
    with SingleTickerProviderStateMixin {
  final _repo = getIt<ReferralRepo>();
  final _codeController = TextEditingController();

  ReferralInfo? _info;
  List<ReferredFriend> _friends = const [];
  bool _loadFailed = false;
  bool _applying = false;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _repo.getMy();
      final friends = await _repo.getInvited();
      if (!mounted) return;
      setState(() {
        _info = info;
        _friends = friends;
        _loadFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: 'referral_title'.tr(),
        onBack: () => context.router.maybePop(),
      ),
      body: info == null
          ? Center(
              child: _loadFailed
                  ? TextButton(
                      onPressed: () {
                        setState(() => _loadFailed = false);
                        _load();
                      },
                      child: 'try_again'.tr().text(15, 20, 600),
                    )
                  : const CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _hero(context, info),
                  const SizedBox(height: 14),
                  _progressCard(context, info),
                  const SizedBox(height: 14),
                  _codeCard(context, info),
                  if (info.hasDiscount) ...[
                    const SizedBox(height: 14),
                    _discountCard(context, info),
                  ],
                  if (info.canApplyCode) ...[
                    const SizedBox(height: 14),
                    _applyCard(context),
                  ],
                  const SizedBox(height: 14),
                  _statsRow(context, info),
                  const SizedBox(height: 14),
                  _friendsCard(context),
                  const SizedBox(height: 14),
                  _howItWorks(context, info),
                ],
              ),
            ),
    );
  }

  Widget _hero(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: const Alignment(1.3, -0.9),
          radius: 1.5,
          colors: [colors.honeydew, colors.mintGreen],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.mintGreen.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_float.value);
              return Transform.translate(
                offset: Offset(0, -8 * t),
                child: child,
              );
            },
            child: Assets.images.premiumFire.image(height: 92),
          ),
          const SizedBox(height: 12),
          'referral_hero_title'
              .tr()
              .text(19, 24, 700)
              .c(colors.textWhite)
              .copyWith(textAlign: TextAlign.center),
          const SizedBox(height: 6),
          'referral_hero_sub'
              .tr(
                namedArgs: {
                  'friends': '${info.friendsGoal}',
                  'days': '${info.premiumDays}',
                },
              )
              .text(14, 18, 500)
              .c(colors.textWhite.withValues(alpha: 0.9))
              .copyWith(textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _progressCard(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: 'referral_progress_title'
                    .tr(namedArgs: {'days': '${info.premiumDays}'})
                    .text(15, 20, 600)
                    .c(colors.textStrong),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_rounded, size: 16, color: colors.accentSub),
                  const SizedBox(width: 4),
                  '${info.progressFriends}/${info.friendsGoal}'
                      .text(14, 18, 700)
                      .c(colors.accentSub),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < info.friendsGoal; i++)
                Expanded(
                  child: Container(
                    height: 10,
                    margin: EdgeInsets.only(
                      right: i == info.friendsGoal - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: i < info.progressFriends
                          ? colors.mintGreen
                          : colors.backgroundElevation,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          'referral_progress_hint'
              .tr(
                namedArgs: {
                  'left': '${info.friendsLeft}',
                  'days': '${info.premiumDays}',
                },
              )
              .text(13, 18, 500)
              .c(colors.textSub),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'referral_code'.tr().text(13, 16, 400).c(colors.textSub),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.backgroundElevation,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.strokeSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: info.code.text(16, 20, 700).c(colors.textStrong),
                ),
                GestureDetector(
                  onTap: () => _copyCode(info.code),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: colors.accentSub,
                      ),
                      const SizedBox(width: 4),
                      'copy_action'.tr().text(13, 16, 600).c(colors.accentSub),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _shareCode(info),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSub,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_rounded, size: 18, color: colors.textWhite),
                  const SizedBox(width: 8),
                  'share_action'.tr().text(15, 20, 600).c(colors.textWhite),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// For a user who joined with a friend's code: their first Premium is
  /// cheaper. Shown until that discount is used.
  Widget _discountCard(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.honeydew,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.paleGreen),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: colors.accentSub, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: 'referral_discount_card'
                .tr(
                  namedArgs: {
                    'name': info.referredBy ?? '',
                    'percent': '${info.discountPercent}',
                  },
                )
                .text(14, 19, 600)
                .c(colors.textStrong),
          ),
        ],
      ),
    );
  }

  /// A new user who skipped the code at sign-up can still confirm it here
  /// (the server allows it for a few days after registration).
  Widget _applyCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'invite_code_question'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'CALORA-XXXX',
                    isDense: true,
                    filled: true,
                    fillColor: colors.backgroundElevation,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.strokeSoft),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _applying ? null : _applyCode,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentSub,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _applying
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textWhite,
                          ),
                        )
                      : 'confirm_action'
                            .tr()
                            .text(14, 18, 600)
                            .c(colors.textWhite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, ReferralInfo info) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            context,
            icon: Icons.person_add_alt_1_rounded,
            value: '${info.invited}',
            label: 'referral_invited'.tr(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            context,
            icon: Icons.verified_rounded,
            value: '${info.active}',
            label: 'referral_active'.tr(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            context,
            icon: Icons.workspace_premium_rounded,
            value: '${info.premiumsEarned}',
            label: 'referral_premiums'.tr(),
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colors = context.colors;
    return _card(
      context,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.accentSub),
          const SizedBox(height: 10),
          value.text(22, 26, 700).c(colors.textStrong),
          const SizedBox(height: 2),
          label.text(12, 15, 400).c(colors.textSub),
        ],
      ),
    );
  }

  /// Everyone who joined with the code and whether they're in the app yet —
  /// only friends who finished onboarding count toward Premium.
  Widget _friendsCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'referral_friends_title'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 8),
          if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: 'referral_friends_empty'
                  .tr()
                  .text(13, 18, 400)
                  .c(colors.textSub),
            )
          else
            for (final friend in _friends) _friendRow(context, friend),
        ],
      ),
    );
  }

  Widget _friendRow(BuildContext context, ReferredFriend friend) {
    final colors = context.colors;
    final active = friend.status == ReferredFriendStatus.active;
    final name = friend.name.trim().isEmpty ? '—' : friend.name.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.lightGreen,
            child: name.characters.first
                .toUpperCase()
                .text(14, 18, 700)
                .c(colors.accentSub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name.text(14, 18, 600).c(colors.textStrong),
                const SizedBox(height: 2),
                _formatDate(
                  friend.activatedAt ?? friend.joinedAt,
                ).text(12, 15, 400).c(colors.textSub),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? colors.lightGreen : colors.backgroundElevation,
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                (active ? 'referral_status_active' : 'referral_status_joined')
                    .tr()
                    .text(12, 14, 600)
                    .c(active ? colors.accentSub : colors.textSub),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'how_it_works'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 12),
          _step(context, 1, 'referral_step_1'.tr()),
          _step(context, 2, 'referral_step_2'.tr()),
          _step(
            context,
            3,
            'referral_step_3'.tr(
              namedArgs: {
                'friends': '${info.friendsGoal}',
                'days': '${info.premiumDays}',
              },
            ),
          ),
          _step(
            context,
            4,
            'referral_step_4'.tr(
              namedArgs: {'percent': '${info.discountPercent}'},
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int n, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: '$n'.text(13, 16, 700).c(colors.accentSub),
          ),
          const SizedBox(width: 12),
          Expanded(child: text.text(14, 18, 500).c(colors.textStrong)),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    try {
      final result = await _repo.apply(code);
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
      _codeController.clear();
      await _load();
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, referralErrorText(e));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    CustomSnackBar.show(context, 'copied'.tr());
  }

  void _shareCode(ReferralInfo info) {
    SharePlus.instance.share(
      ShareParams(
        text: 'referral_share_text'.tr(
          namedArgs: {'code': info.code, 'percent': '${info.discountPercent}'},
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Maps the backend's referral error codes to a user-facing message.
String referralErrorText(Object error) => switch (error.apiErrorCode) {
  'referral_code_not_found' => 'invite_code_not_found'.tr(),
  'referral_already_applied' => 'invite_code_already_applied'.tr(),
  'referral_self' => 'invite_code_self'.tr(),
  'referral_window_expired' => 'invite_code_expired'.tr(),
  _ => 'something_went_wrong'.tr(),
};
