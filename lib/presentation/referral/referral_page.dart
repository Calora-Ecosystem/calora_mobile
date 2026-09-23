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

/// App download link appended to every invite message.
const String _appLink =
    'https://calora.uz/get-app?utm_source=ig&utm_medium=social&utm_content=link_in_bio&fbclid=PAdGRleAUgr35wZG9mAmZkaWQWUO_31iVOcBg-gWrPQuL6s370ESIfzWV4dG4DYWVtAjExAHNydGMGYXBwX2lkDzEyNDAyNDU3NDI4NzQxNAABp-RykBP5lisCPJ-X3snDgwSdcroKjwcpCcZ_RnSyX9FvyV-n1iHvtG_wxDmN_aem_dKS_Q99npN7Yml6Ale4vNg';

/// Referral screen — share an invite code; every [ReferralInfo.friendsGoal]
/// friends who confirm it and start using the app earn
/// [ReferralInfo.premiumDays] days of Premium. Each share gets a fresh code
/// (all earlier codes keep working). It is also the one place where a user
/// confirms the code of the friend who invited them, which unlocks a
/// first-purchase discount. Data: `referrals/me`, `referrals/invited`,
/// `referrals/code`.
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
  String _code = '';
  List<ReferredFriend> _friends = const [];
  bool _loadFailed = false;
  bool _applying = false;
  bool _sharing = false;

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
        _code = info.code;
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
                  const SizedBox(height: 16),
                  _progressCard(context, info),
                  const SizedBox(height: 12),
                  _codeCard(context),
                  const SizedBox(height: 12),
                  _statsRow(context, info),
                  const SizedBox(height: 12),
                  info.isReferred
                      ? _referredCard(context, info)
                      : _applyCard(context),
                  const SizedBox(height: 12),
                  _friendsCard(context),
                  const SizedBox(height: 12),
                  _howItWorks(context, info),
                ],
              ),
            ),
    );
  }

  /// "1 month" for multiples of 30 days, otherwise "N days".
  String _period(int days) => days % 30 == 0
      ? 'referral_period_months'.tr(namedArgs: {'count': '${days ~/ 30}'})
      : 'referral_period_days'.tr(namedArgs: {'count': '$days'});

  Widget _hero(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: const Alignment(1.3, -0.9),
          radius: 1.5,
          colors: [colors.honeydew, colors.mintGreen],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.mintGreen.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
                offset: Offset(0, -6 * t),
                child: child,
              );
            },
            child: Assets.images.premiumFire.image(height: 76),
          ),
          const SizedBox(height: 12),
          'referral_hero_title'
              .tr(
                namedArgs: {
                  'friends': '${info.friendsGoal}',
                  'period': _period(info.premiumDays),
                },
              )
              .text(21, 26, 700)
              .c(colors.textWhite)
              .copyWith(textAlign: TextAlign.center),
          const SizedBox(height: 6),
          'referral_hero_sub'
              .tr()
              .text(14, 19, 500)
              .c(colors.textWhite.withValues(alpha: 0.92))
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
                    .tr()
                    .text(15, 20, 600)
                    .c(colors.textStrong),
              ),
              '${info.progressFriends}/${info.friendsGoal}'
                  .text(15, 20, 700)
                  .c(colors.accentSub),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < info.friendsGoal; i++)
                Expanded(
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(
                      right: i == info.friendsGoal - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: i < info.progressFriends
                          ? colors.mintGreen
                          : colors.backgroundElevation,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          'referral_progress_hint'
              .tr(namedArgs: {'left': '${info.friendsLeft}'})
              .text(13, 17, 500)
              .c(colors.textSub),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'referral_code'.tr().text(13, 16, 500).c(colors.textSub),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: colors.backgroundElevation,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.strokeSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _code,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colors.textStrong,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyCode,
                  icon: Icon(Icons.copy_rounded, color: colors.accentSub),
                  tooltip: 'copy_action'.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _sharing ? null : _share,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSub,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _sharing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textWhite,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                          color: colors.textWhite,
                        ),
                        const SizedBox(width: 8),
                        'share_action'
                            .tr()
                            .text(15, 20, 600)
                            .c(colors.textWhite),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Three equal tiles: signed up, in the app, Premiums earned.
  Widget _statsRow(BuildContext context, ReferralInfo info) {
    final tiles = [
      (Icons.person_add_alt_1_rounded, info.invited, 'referral_invited'),
      (Icons.verified_rounded, info.active, 'referral_active'),
      (
        Icons.workspace_premium_rounded,
        info.premiumsEarned,
        'referral_premiums',
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              context,
              icon: tiles[i].$1,
              value: tiles[i].$2,
              label: tiles[i].$3.tr(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required int value,
    required String label,
  }) {
    final colors = context.colors;
    return _card(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: SizedBox(
        height: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: colors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colors.accentSub),
            ),
            const SizedBox(height: 8),
            '$value'.text(20, 24, 700).c(colors.textStrong),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 15 / 12,
                fontWeight: FontWeight.w500,
                color: colors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Once the user has confirmed a friend's code: who invited them and, while
  /// unused, their first-Premium discount. A code is confirmed only once.
  Widget _referredCard(BuildContext context, ReferralInfo info) {
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
          Icon(
            info.hasDiscount
                ? Icons.card_giftcard_rounded
                : Icons.verified_rounded,
            color: colors.accentSub,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                (info.hasDiscount
                        ? 'referral_discount_card'
                        : 'invite_code_confirmed')
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

  /// Where the user confirms the code of the friend who invited them — the
  /// only place a code is entered. Any account can do it, once.
  Widget _applyCard(BuildContext context) {
    final colors = context.colors;
    final canSubmit = _codeController.text.trim().isNotEmpty && !_applying;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'invite_code_question'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 4),
          'invite_code_hint'.tr().text(13, 17, 400).c(colors.textSub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _applyCode(),
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: colors.textStrong,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CALORA-XXXXXX',
                    isDense: true,
                    filled: true,
                    fillColor: colors.backgroundElevation,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.strokeSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.accentSub),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: canSubmit ? _applyCode : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canSubmit
                        ? colors.accentSub
                        : colors.accentSub.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
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

  /// Everyone who confirmed the code and whether they're in the app yet —
  /// only friends who finished onboarding count toward Premium.
  Widget _friendsCard(BuildContext context) {
    final colors = context.colors;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'referral_friends_title'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 6),
          if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: 'referral_friends_empty'
                  .tr()
                  .text(13, 18, 400)
                  .c(colors.textSub),
            )
          else
            for (int i = 0; i < _friends.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.strokeSoft),
              _friendRow(context, _friends[i]),
            ],
        ],
      ),
    );
  }

  Widget _friendRow(BuildContext context, ReferredFriend friend) {
    final colors = context.colors;
    final active = friend.status == ReferredFriendStatus.active;
    final name = friend.name.trim().isEmpty ? '—' : friend.name.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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

  /// Four short steps on a vertical timeline.
  Widget _howItWorks(BuildContext context, ReferralInfo info) {
    final colors = context.colors;
    final steps = [
      'referral_step_1'.tr(),
      'referral_step_2'.tr(),
      'referral_step_3'.tr(
        namedArgs: {
          'friends': '${info.friendsGoal}',
          'period': _period(info.premiumDays),
        },
      ),
      'referral_step_4'.tr(namedArgs: {'percent': '${info.discountPercent}'}),
    ];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'how_it_works'.tr().text(15, 20, 600).c(colors.textStrong),
          const SizedBox(height: 14),
          for (int i = 0; i < steps.length; i++)
            _step(context, i + 1, steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _step(
    BuildContext context,
    int n,
    String text, {
    required bool isLast,
  }) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.lightGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.paleGreen),
                  ),
                  child: '$n'.text(13, 16, 700).c(colors.accentSub),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.paleGreen,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
              child: text.text(14, 19, 500).c(colors.textStrong),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared card look for the whole screen: white, rounded 20, hairline
  /// border and a soft lift.
  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
  }) {
    final colors = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.strokeSoft),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _applying) return;
    FocusScope.of(context).unfocus();
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

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    CustomSnackBar.show(context, 'copied'.tr());
  }

  /// Every share gets a fresh code, so the same code isn't sent twice; the
  /// message carries the app download link.
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final code = await _repo.newCode();
      if (!mounted) return;
      setState(() => _code = code);
      await SharePlus.instance.share(
        ShareParams(
          text: 'referral_share_text'.tr(
            namedArgs: {
              'code': code,
              'percent': '${_info?.discountPercent ?? 10}',
              'link': _appLink,
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) CustomSnackBar.show(context, 'something_went_wrong'.tr());
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
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
