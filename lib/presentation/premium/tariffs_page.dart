import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/family/family_redeem_sheet.dart';
import 'package:calora/presentation/premium/family/person_avatar.dart';
import 'package:calora/presentation/premium/premium_sheet.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Tariff { yearly, monthly, family }

/// Tariff picker: yearly, monthly and family (two people, one subscription).
///
/// A plain, list-style plan chooser: one row per plan with the price where
/// the eye expects it, the family options unfolding only when that plan is
/// picked, and a single summary of what is paid today above the button.
///
/// Every price comes from the backend packages the admin manages in the
/// dashboard: the regular 1- and 12-month packages and the family package.
/// A package that isn't set up (or is switched off) simply isn't shown.
/// "Continue" opens the real [PremiumSheet] with the chosen package already
/// selected; after paying for the family plan the buyer gets a Premium code
/// for the second person, who redeems it from the link at the bottom
/// ([FamilyRedeemSheet]).
@RoutePage()
class TariffsPage extends StatefulWidget {
  const TariffsPage({super.key});

  /// The family plan is for two people (the buyer plus one code).
  static const familySize = 2;

  @override
  State<TariffsPage> createState() => _TariffsPageState();
}

class _TariffsPageState extends State<TariffsPage>
    with SingleTickerProviderStateMixin {
  _Tariff _selected = _Tariff.yearly;

  List<PremiumPlanModel> _regular = const [];
  PremiumPlanModel? _familyPlan;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repo = getIt<PremiumRepo>();
      final results = await Future.wait([
        repo.getPremiumPlans(),
        repo.getPremiumPlans(family: true),
      ]);
      if (!mounted) return;
      setState(() {
        _regular = results[0];
        // A backend that doesn't know `family=true` answers with the regular
        // list — never sell one of those as the family plan.
        _familyPlan = results[1].firstWhereOrNull((p) => p.isFamily ?? false);
        _loading = false;
        final available = _available;
        if (!available.contains(_selected) && available.isNotEmpty) {
          _selected = available.first;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  PremiumPlanModel? _regularFor(int months) =>
      _regular.firstWhereOrNull((p) => p.duration == months);

  PremiumPlanModel? get _monthly => _regularFor(1);
  PremiumPlanModel? get _yearly => _regularFor(12);

  PremiumPlanModel? _planOf(_Tariff tariff) => switch (tariff) {
    _Tariff.yearly => _yearly,
    _Tariff.monthly => _monthly,
    _Tariff.family => _familyPlan,
  };

  /// Tariffs with a backend package, in page order.
  List<_Tariff> get _available =>
      _Tariff.values.where((t) => _planOf(t) != null).toList();

  /// What the sheet will charge on Payme / Click: the referral price when
  /// the user has that discount, otherwise the package fee.
  static int _priceOf(PremiumPlanModel plan) {
    final fee = plan.fee ?? 0;
    return (plan.referralDiscountPercent ?? 0) > 0
        ? plan.discountedFee ?? fee
        : fee;
  }

  /// Drives the staggered entrance of the page blocks ([_Reveal]).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) =>
      _Reveal(animation: _intro, index: index, child: child);

  PremiumPlanModel? get _selectedPlan => _loading ? null : _planOf(_selected);

  int get _price {
    final plan = _selectedPlan;
    return plan == null ? 0 : _priceOf(plan);
  }

  /// Saving of the yearly package against twelve monthly ones, or null when
  /// either package is missing or nothing is saved.
  int? get _yearlySavePercent {
    final monthly = _monthly, yearly = _yearly;
    if (monthly == null || yearly == null) return null;
    final full = _priceOf(monthly) * 12;
    if (full <= 0) return null;
    final percent = (100 - _priceOf(yearly) * 100 / full).round();
    return percent > 0 ? percent : null;
  }

  void _continue() {
    final plan = _selectedPlan;
    if (plan == null) return;
    final family = _selected == _Tariff.family;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PremiumSheet(family: family, initialPlanId: plan.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 8,
                20,
                24,
              ),
              children: [
                _topBar(context),
                const SizedBox(height: 20),
                _reveal(
                  0,
                  'tf_choose_title'.tr().text(26, 32, 700).c(colors.textStrong),
                ),
                const SizedBox(height: 8),
                _reveal(
                  1,
                  'tf_subtitle'.tr().text(14, 20, 400).c(colors.textSub),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  _reveal(2, const _PlanSkeleton())
                else if (_failed || _available.isEmpty)
                  _reveal(2, _loadFailed(context))
                else
                  ..._planTiles(context),
                const SizedBox(height: 28),
                _reveal(5, _included(context)),
                const SizedBox(height: 20),
                _reveal(6, _assurances(context)),
                const SizedBox(height: 8),
                _reveal(7, _familyCodeLink(context)),
              ],
            ),
          ),
          _bottomBar(context),
        ],
      ),
    );
  }

  /// One row per backend package, spaced like the rest of the list.
  List<Widget> _planTiles(BuildContext context) {
    final monthly = _monthly, yearly = _yearly, family = _familyPlan;
    final savePercent = _yearlySavePercent;
    final tiles = <Widget>[
      if (yearly != null)
        _PlanTile(
          selected: _selected == _Tariff.yearly,
          onTap: () => setState(() => _selected = _Tariff.yearly),
          title: 'tf_yearly'.tr(),
          tag: savePercent == null
              ? null
              : 'tf_best_value'.tr(namedArgs: {'percent': '$savePercent'}),
          tagFilled: true,
          subtitle: 'tf_yearly_sub'.tr(
            namedArgs: {
              // Non-breaking separator keeps "33 250" on one line.
              'price': (_priceOf(yearly) / 12).formatPrice(separator: ' '),
            },
          ),
          price: _priceOf(yearly),
          period: 'tf_per_year'.tr(),
          struckPrice: savePercent == null ? null : _priceOf(monthly!) * 12,
        ),
      if (monthly != null)
        _PlanTile(
          selected: _selected == _Tariff.monthly,
          onTap: () => setState(() => _selected = _Tariff.monthly),
          title: 'tf_monthly'.tr(),
          subtitle: 'tf_monthly_sub'.tr(),
          price: _priceOf(monthly),
          period: 'tf_per_month'.tr(),
        ),
      if (family != null)
        _FamilyCard(
          selected: _selected == _Tariff.family,
          onTap: () => setState(() => _selected = _Tariff.family),
          price: _priceOf(family),
          months: family.duration ?? 1,
          singleMonthly: monthly == null ? null : _priceOf(monthly),
        ),
    ];
    return [
      for (final (i, tile) in tiles.indexed) ...[
        if (i > 0) const SizedBox(height: 12),
        _reveal(2 + i, tile),
      ],
    ];
  }

  /// No package could be loaded — say so and offer a retry instead of
  /// showing a price that may not be the real one.
  Widget _loadFailed(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.softGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: 'something_went_wrong'
                .tr()
                .text(14, 20, 500)
                .c(colors.textStrong),
          ),
          TextButton(
            onPressed: _load,
            child: 'try_again'.tr().text(14, 18, 600).c(colors.accentSub),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.router.maybePop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.softGray,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: colors.textStrong,
            ),
          ),
        ),
        const Spacer(),
        'Calora Premium'.text(14, 18, 600).c(colors.textSub),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _included(BuildContext context) {
    final colors = context.colors;
    const features = [
      'tf_feature_ai',
      'tf_feature_voice',
      'tf_feature_report',
      'tf_feature_workouts',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        'tf_included'.tr().text(16, 22, 700).c(colors.textStrong),
        const SizedBox(height: 12),
        for (final key in features)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colors.accentSub,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: key.tr().text(14, 20, 400).c(colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _assurances(BuildContext context) {
    final colors = context.colors;
    Widget item(IconData icon, String key) => Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textSub),
          const SizedBox(width: 6),
          Expanded(
            child: key
                .tr()
                .text(12, 16, 500)
                .c(colors.textSub)
                .copyWith(maxLines: 2),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.softGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          item(Icons.lock_outline_rounded, 'tf_secure'),
          const SizedBox(width: 12),
          item(Icons.event_repeat_rounded, 'tf_cancel_anytime'),
        ],
      ),
    );
  }

  /// For the second person of a family plan: they got a code, not a bill.
  Widget _familyCodeLink(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: TextButton(
        onPressed: () => FamilyRedeemSheet.show(context),
        child: 'tf_have_family_code'.tr().text(14, 18, 600).c(colors.accentSub),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(top: BorderSide(color: colors.strokeSoft)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPlan != null)
              Row(
                children: [
                  Expanded(
                    child: 'tf_due_today'
                        .tr()
                        .text(14, 18, 500)
                        .c(colors.textSub),
                  ),
                  _CountingPrice(
                    value: _price,
                    suffix: 'tf_sum'.tr(),
                    style: TextStyle(
                      fontFamily: FontFamily.inter,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textStrong,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedPlan == null ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentSub,
                  foregroundColor: colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: 'tf_continue'.tr().text(16, 20, 600).c(colors.white),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_selected == _Tariff.yearly),
                child:
                    (_selected == _Tariff.yearly
                            ? 'tf_billed_yearly'
                            : 'tf_billed_monthly')
                        .tr()
                        .text(11, 14, 400)
                        .c(colors.textSub)
                        .auto(minSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plan row: radio, name (+ optional tag) and a one-line explanation on
/// the left, price and billing period on the right.
class _PlanTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? tag;
  final bool tagFilled;
  final int price;
  final String period;
  final int? struckPrice;

  const _PlanTile({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    this.tag,
    this.tagFilled = false,
    required this.price,
    required this.period,
    this.struckPrice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: selected
              ? colors.accentGreenWhite.withValues(alpha: 0.55)
              : colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accentSub : colors.strokeSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: _Radio(selected: selected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          title.text(16, 22, 600).c(colors.textStrong),
                          if (tag != null) _Tag(text: tag!, filled: tagFilled),
                        ],
                      ),
                      const SizedBox(height: 3),
                      subtitle
                          .text(13, 18, 400)
                          .c(colors.textSub)
                          .copyWith(maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Price(price: price, period: period, struck: struckPrice),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Family plan: one subscription for two people.
///
/// The pitch is the price, so the card shows it per person instead of in
/// words — two separate plans above one shared plan ([_FamilyPriceCompare]).
/// Once picked, it unfolds three short steps explaining how the second
/// person joins.
class _FamilyCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  /// Family package price for [months] (from the dashboard).
  final int price;
  final int months;

  /// Regular monthly price — what each person would pay alone. Null without
  /// a monthly package, and then there is nothing to compare against.
  final int? singleMonthly;

  const _FamilyCard({
    required this.selected,
    required this.onTap,
    required this.price,
    required this.months,
    required this.singleMonthly,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final familyMonthly = (price / months).round();
    final single = singleMonthly;
    // The comparison only argues for the family plan when it does save.
    final compare =
        single != null && familyMonthly < single * TariffsPage.familySize;
    final period = switch (months) {
      1 => 'tf_per_month'.tr(),
      12 => 'tf_per_year'.tr(),
      _ => 'plan_n_months'.tr(namedArgs: {'count': '$months'}),
    };

    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? colors.accentGreenWhite.withValues(alpha: 0.55)
              : colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accentSub : colors.strokeSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: _Radio(selected: selected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          'tf_family'
                              .tr()
                              .text(16, 22, 600)
                              .c(colors.textStrong),
                          _Tag(text: 'tf_new'.tr(), filled: false),
                        ],
                      ),
                      const SizedBox(height: 3),
                      'tf_family_sub'
                          .tr()
                          .text(13, 18, 400)
                          .c(colors.textSub)
                          .copyWith(maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Price(price: price, period: period),
              ],
            ),
            if (compare) ...[
              const SizedBox(height: 16),
              _FamilyPriceCompare(
                active: selected,
                single: single,
                family: familyMonthly,
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: selected
                  ? const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: _FamilySteps(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-person price, drawn rather than described.
///
/// Top row: two people, each in their own box with the regular monthly
/// price — two separate subscriptions. Bottom row: the same two people
/// inside ONE box at half the family price each — one shared subscription.
/// Both rows share the same column geometry, so each person's price drop
/// reads straight down the column. All amounts are per month and come from
/// the backend packages.
///
/// Plays once, the first time it is (almost) fully on screen (or when the family plan
/// is picked): the separate plans settle in, the two people move together
/// into the shared box while their price counts down to their share, and
/// the monthly saving lands last.
class _FamilyPriceCompare extends StatefulWidget {
  /// The family plan is selected — starts the story if it hasn't run yet.
  final bool active;

  /// Regular monthly price for one person.
  final int single;

  /// Family price per month, for both people together.
  final int family;

  const _FamilyPriceCompare({
    required this.active,
    required this.single,
    required this.family,
  });

  @override
  State<_FamilyPriceCompare> createState() => _FamilyPriceCompareState();
}

class _FamilyPriceCompareState extends State<_FamilyPriceCompare>
    with SingleTickerProviderStateMixin {
  static const double _gap = 8;
  static const double _pad = 10;

  late final AnimationController _story = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  ScrollableState? _scrollable;
  bool _started = false;
  bool _checkQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _story.value = 1;
    }
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != _scrollable) {
      _scrollable?.position.removeListener(_queueCheck);
      _scrollable = scrollable;
      _scrollable?.position.addListener(_queueCheck);
    }
    _queueCheck();
  }

  @override
  void didUpdateWidget(_FamilyPriceCompare old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _start();
  }

  /// Scroll notifications arrive before the new layout, so measure on the
  /// next frame, once positions are current.
  void _queueCheck() {
    if (_started || _checkQueued) return;
    _checkQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQueued = false;
      _checkVisible();
    });
  }

  void _checkVisible() {
    if (_started || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final viewport = _scrollable?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    if (viewport == null || !viewport.attached || !viewport.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom =
        viewport.localToGlobal(Offset.zero).dy + viewport.size.height;
    if (top + box.size.height * 0.85 <= bottom) _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    _scrollable?.position.removeListener(_queueCheck);
    _story.forward();
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_queueCheck);
    _story.dispose();
    super.dispose();
  }

  /// Progress of one beat of the story, 0 → 1.
  double _beat(double from, double to) =>
      Interval(from, to, curve: Curves.easeOutCubic).transform(_story.value);

  /// Counting prices move in 500-sum steps so digits don't flicker.
  static int _stepped(double value) => (value / 500).round() * 500;

  static Widget _rise(double t, Widget child, {double dy = 8}) => Opacity(
    opacity: t,
    child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final single = widget.single;
    final separate = single * TariffsPage.familySize;
    final family = widget.family;
    final each = family ~/ TariffsPage.familySize;
    final sum = 'tf_sum'.tr();
    final you = 'tf_person_you'.tr();
    final partner = 'tf_person_partner'.tr();

    Widget header(String label, int total, {required bool strong}) => Row(
      children: [
        Expanded(
          child: label
              .text(12, 16, strong ? 600 : 500)
              .c(strong ? colors.textStrong : colors.textSub),
        ),
        const SizedBox(width: 8),
        '${total.formatPrice()} $sum'
            .text(12, 16, strong ? 700 : 500)
            .c(strong ? colors.accentSub : colors.textSub),
      ],
    );

    BoxDecoration box({required bool shared}) => BoxDecoration(
      color: colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: shared ? colors.accentSub : colors.strokeSoft),
    );

    return AnimatedBuilder(
      animation: _story,
      builder: (context, _) {
        final separateIn = _beat(0.12, 0.38);
        final sharedIn = _beat(0.34, 0.58);
        final join = _beat(0.40, 0.76);
        final count = _beat(0.44, 0.86);
        final saveIn = _beat(0.78, 1);

        final price = _stepped(single + (each - single) * count);
        final saving = _stepped((separate - family) * saveIn);

        // Each person starts a little apart and slides into the shared box.
        Widget joining(Widget child, {required bool fromLeft}) => Opacity(
          opacity: join,
          child: Transform.translate(
            offset: Offset((fromLeft ? -14 : 14) * (1 - join), 0),
            child: child,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rise(
              separateIn,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header('tf_family_separately'.tr(), separate, strong: false),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (i, name) in [you, partner].indexed) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(_pad),
                            decoration: box(shared: false),
                            child: _PersonPrice(
                              name: name,
                              price: single,
                              muted: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _rise(
              sharedIn,
              header('tf_family_plan_row'.tr(), family, strong: true),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: sharedIn,
              child: Transform.scale(
                scale: 0.96 + 0.04 * sharedIn,
                child: Container(
                  decoration: box(shared: true),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(_pad),
                          child: joining(
                            _PersonPrice(name: you, price: price),
                            fromLeft: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(_pad),
                          child: joining(
                            _PersonPrice(
                              name: partner,
                              price: price,
                              second: true,
                            ),
                            fromLeft: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _rise(
              saveIn,
              dy: 4,
              Row(
                children: [
                  Icon(Icons.south_rounded, size: 14, color: colors.accentSub),
                  const SizedBox(width: 6),
                  Expanded(
                    child: 'tf_family_save'
                        .tr(namedArgs: {'price': saving.formatPrice()})
                        .text(12, 16, 600)
                        .c(colors.accentSub),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One person in the comparison: avatar, who it is, what they pay a month.
class _PersonPrice extends StatelessWidget {
  final String name;
  final int price;

  /// Separate-plan row: greyed out, it is the option being argued against.
  final bool muted;

  /// The person you add — a warm tint so the pair reads as two people.
  final bool second;

  const _PersonPrice({
    required this.name,
    required this.price,
    this.muted = false,
    this.second = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = muted
        ? (colors.softGray, colors.iconSoft)
        : second
        ? (PersonAvatar.partnerBackground, PersonAvatar.partnerForeground)
        : (colors.accentSub, colors.white);

    return Row(
      children: [
        PersonAvatar(size: 30, background: bg, foreground: fg),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name.text(11, 14, 500).c(colors.textSub).auto(minSize: 9),
              const SizedBox(height: 1),
              Text(
                price.formatPrice(),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: FontFamily.inter,
                  fontSize: 15,
                  height: 20 / 15,
                  fontWeight: FontWeight.w700,
                  color: muted ? colors.textSub : colors.textStrong,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Plan rows while the backend packages load.
class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.softGray,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Column(
      children: [
        row(78),
        const SizedBox(height: 12),
        row(78),
        const SizedBox(height: 12),
        row(150),
      ],
    );
  }
}

/// How the second person gets in — shown once the family plan is picked.
class _FamilySteps extends StatelessWidget {
  const _FamilySteps();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = ['tf_family_step_1', 'tf_family_step_2', 'tf_family_step_3'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        'tf_family_how'.tr().text(13, 18, 600).c(colors.textStrong),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accentSub),
                  ),
                  child: '${i + 1}'.text(11, 13, 700).c(colors.accentSub),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: steps[i].tr().text(13, 19, 400).c(colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Page entrance: each block fades in and rises a few pixels, one after
/// another, off a single controller owned by the page.
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _Reveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  static const double _stagger = 0.07;
  static const double _span = 0.5;

  @override
  Widget build(BuildContext context) {
    final start = (index * _stagger).clamp(0.0, 1 - _span);
    final interval = Interval(start, start + _span, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tap target that gives way slightly under the finger, with a selection
/// tick — plan rows feel like physical options rather than flat links.
class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A price that counts to its new value instead of jumping, in 500-sum steps
/// with tabular digits so the width stays put while it moves.
class _CountingPrice extends StatelessWidget {
  final int value;
  final String suffix;
  final TextStyle style;

  const _CountingPrice({
    required this.value,
    required this.suffix,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${((v / 500).round() * 500).formatPrice()} $suffix',
        maxLines: 1,
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  final int price;
  final String period;
  final int? struck;

  const _Price({required this.price, required this.period, this.struck});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: price
              .formatPrice()
              .text(16, 22, 700)
              .c(colors.textStrong)
              .copyWith(key: ValueKey(price)),
        ),
        '${'tf_sum'.tr()} / $period'.text(12, 16, 400).c(colors.textSub),
        if (struck != null) ...[
          const SizedBox(height: 2),
          Text(
            '${struck!.formatPrice()} ${'tf_sum'.tr()}',
            style: TextStyle(
              color: colors.textSub,
              decoration: TextDecoration.lineThrough,
              decorationColor: colors.textSub,
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w400,
              fontFamily: FontFamily.inter,
            ),
          ),
        ],
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;

  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.white,
        border: Border.all(
          color: selected ? colors.accentSub : colors.iconSoft,
          width: selected ? 6.5 : 1.5,
        ),
      ),
    );
  }
}

/// Small inline label next to a plan name ("Best value · −32%", "New").
class _Tag extends StatelessWidget {
  final String text;
  final bool filled;

  const _Tag({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? colors.accentSub : null,
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: colors.strokeSoft),
      ),
      child: text.text(11, 14, 600).c(filled ? colors.white : colors.textSub),
    );
  }
}
