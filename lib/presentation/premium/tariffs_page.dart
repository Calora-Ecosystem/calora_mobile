import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
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

@RoutePage()
class TariffsPage extends StatefulWidget {
  const TariffsPage({super.key});

  static const familySize = 2;

  @override
  State<TariffsPage> createState() => _TariffsPageState();
}

class _TariffsPageState extends State<TariffsPage>
    with SingleTickerProviderStateMixin {
  List<PlanGroup> _groups = const [];
  PremiumPlanModel? _selected;
  bool _loading = true;
  bool _failed = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final plans = await getIt<PremiumRepo>().getPremiumPlans();
      if (!mounted) return;
      final groups = PlanGroup.of(plans);
      setState(() {
        _groups = groups;
        _selected = _initialSelection(groups);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  PremiumPlanModel? _initialSelection(List<PlanGroup> groups) {
    final packages = groups.expand((group) => group.packages);
    return packages.firstWhereOrNull((p) => p.id == _selected?.id) ??
        packages.firstWhereOrNull((p) => p.isPopular) ??
        packages.firstOrNull;
  }

  PlanGroup? _group(SubscriptionPlanType type) =>
      _groups.firstWhereOrNull((group) => group.type == type);

  PremiumPlanModel? get _premiumMonthly =>
      _group(SubscriptionPlanType.premium)?.byDuration(1);

  int? _struckPrice(PlanGroup group, PremiumPlanModel package) {
    final people = group.isFamily ? TariffsPage.familySize : 1;
    final separately = (_premiumMonthly?.fee ?? 0) * package.duration * people;
    final struck = [package.originalFee, package.fee, separately].max;
    return struck > package.price ? struck : null;
  }

  Widget _reveal(int index, Widget child) =>
      _Reveal(animation: _intro, index: index, child: child);

  void _continue() {
    final selected = _selected;
    final group = selected == null ? null : _group(selected.type);
    if (selected == null || group == null) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          PremiumSheet(packages: group.packages, initialPlanId: selected.id),
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
                else if (_failed || _groups.isEmpty)
                  _reveal(2, _loadFailed(context))
                else
                  ..._groupSections(),
                const SizedBox(height: 28),
                _reveal(6, _included(context)),
                const SizedBox(height: 20),
                _reveal(7, _assurances(context)),
                const SizedBox(height: 8),
                _reveal(8, _familyCodeLink(context)),
              ],
            ),
          ),
          _bottomBar(context),
        ],
      ),
    );
  }

  List<Widget> _groupSections() {
    var index = 2;
    return [
      for (final (i, group) in _groups.indexed) ...[
        if (i > 0) const SizedBox(height: 28),
        _reveal(index++, _GroupHeader(group: group)),
        const SizedBox(height: 12),
        for (final (j, package) in group.packages.indexed) ...[
          if (j > 0) const SizedBox(height: 12),
          _reveal(index++, _tile(group, package)),
        ],
      ],
    ];
  }

  Widget _tile(PlanGroup group, PremiumPlanModel package) {
    final months = package.duration;
    final selected = _selected?.id == package.id;
    final struck = _struckPrice(group, package);
    final save = struck == null
        ? 0
        : (100 - package.price * 100 / struck).round();
    final familyMonthly = (package.price / months).round();
    final footer = switch (_premiumMonthly?.price) {
      final single?
          when group.isFamily &&
              familyMonthly < single * TariffsPage.familySize =>
        _FamilyPriceCompare(
          active: selected,
          single: single,
          family: familyMonthly,
        ),
      _ => null,
    };

    return _PlanTile(
      selected: selected,
      onTap: () => setState(() => _selected = package),
      title: _durationTitle(months),
      subtitle: switch ((months, group.isFamily)) {
        (1, true) => 'tf_family_sub'.tr(),
        (1, false) => 'tf_monthly_sub'.tr(),
        _ => 'tf_yearly_sub'.tr(
          namedArgs: {
            'price': (package.price / months).formatPrice(separator: ' '),
          },
        ),
      },
      tag: save > 0
          ? 'tf_best_value'.tr(namedArgs: {'percent': '$save'})
          : null,
      tagFilled: package.isPopular,
      price: package.price,
      period: _period(months),
      struckPrice: struck,
      features: package.features.map(_featureLabel).nonNulls.toList(),
      footer: footer,
      expanded: group.isFamily ? const _FamilySteps() : null,
    );
  }

  static String _durationTitle(int months) => switch (months) {
    1 => 'tf_monthly'.tr(),
    12 => 'tf_yearly'.tr(),
    _ => 'plan_n_months'.tr(namedArgs: {'count': '$months'}),
  };

  static String _period(int months) => switch (months) {
    1 => 'tf_per_month'.tr(),
    12 => 'tf_per_year'.tr(),
    _ => 'plan_n_months'.tr(namedArgs: {'count': '$months'}),
  };

  static String? _featureLabel(PlanFeature feature) =>
      switch ((feature.key, feature.value.toLowerCase())) {
        ('AiScans', 'unlimited') => 'premium_feat_scans'.tr(),
        _ => null,
      };

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
    final selected = _loading ? null : _selected;
    final billed = switch (selected?.duration) {
      1 => 'tf_billed_monthly',
      12 => 'tf_billed_yearly',
      _ => null,
    };
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
            if (selected != null)
              Row(
                children: [
                  Expanded(
                    child: 'tf_due_today'
                        .tr()
                        .text(14, 18, 500)
                        .c(colors.textSub),
                  ),
                  _CountingPrice(
                    value: selected.price,
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
                onPressed: selected == null ? null : _continue,
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
            if (billed != null) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(billed),
                  child: billed
                      .tr()
                      .text(11, 14, 400)
                      .c(colors.textSub)
                      .auto(minSize: 9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final PlanGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final family = group.isFamily;
    return Row(
      children: [
        _People(count: family ? TariffsPage.familySize : 1),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: (family ? 'tf_family' : 'plan_premium')
                    .tr()
                    .text(18, 24, 700)
                    .c(colors.textStrong)
                    .copyWith(maxLines: 1),
              ),
              if (family) ...[
                const SizedBox(width: 8),
                _Tag(text: 'tf_new'.tr(), filled: false),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.softGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: (family ? 'tf_two_people' : 'tf_one_person')
              .tr()
              .text(12, 16, 600)
              .c(colors.textSub),
        ),
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.count});

  final int count;

  static const double _size = 26;
  static const double _ring = 2;
  static const double _step = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = [
      (colors.accentSub, colors.white),
      (PersonAvatar.partnerBackground, PersonAvatar.partnerForeground),
    ];
    const outer = _size + _ring * 2;
    return SizedBox(
      width: outer + _step * (count - 1),
      height: outer,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: _step * i,
              child: Container(
                padding: const EdgeInsets.all(_ring),
                decoration: BoxDecoration(
                  color: colors.white,
                  shape: BoxShape.circle,
                ),
                child: PersonAvatar(
                  size: _size,
                  background: palette[i % palette.length].$1,
                  foreground: palette[i % palette.length].$2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
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
    this.features = const [],
    this.footer,
    this.expanded,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? tag;
  final bool tagFilled;
  final int price;
  final String period;
  final int? struckPrice;
  final List<String> features;
  final Widget? footer;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final footer = this.footer;
    final expanded = this.expanded;
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
                          title.text(16, 22, 600).c(colors.textStrong),
                          if (tag case final tag?)
                            _Tag(text: tag, filled: tagFilled),
                        ],
                      ),
                      const SizedBox(height: 3),
                      subtitle
                          .text(13, 18, 400)
                          .c(colors.textSub)
                          .copyWith(maxLines: 2),
                      for (final feature in features)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: colors.accentSub,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: feature
                                    .text(12, 16, 600)
                                    .c(colors.textPrimary)
                                    .copyWith(maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Price(price: price, period: period, struck: struckPrice),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer],
            if (expanded != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: expanded,
                      )
                    : const SizedBox(width: double.infinity),
              ),
          ],
        ),
      ),
    );
  }
}

class _FamilyPriceCompare extends StatefulWidget {
  const _FamilyPriceCompare({
    required this.active,
    required this.single,
    required this.family,
  });

  final bool active;
  final int single;
  final int family;

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

  double _beat(double from, double to) =>
      Interval(from, to, curve: Curves.easeOutCubic).transform(_story.value);

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

class _PersonPrice extends StatelessWidget {
  const _PersonPrice({
    required this.name,
    required this.price,
    this.muted = false,
    this.second = false,
  });

  final String name;
  final int price;
  final bool muted;
  final bool second;

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

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget block(double height, {double? width, double radius = 16}) =>
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: colors.softGray,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        block(26, width: 140, radius: 13),
        const SizedBox(height: 12),
        block(78),
        const SizedBox(height: 12),
        block(78),
        const SizedBox(height: 28),
        block(26, width: 120, radius: 13),
        const SizedBox(height: 12),
        block(150),
      ],
    );
  }
}

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
        for (final (i, step) in steps.indexed)
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
                  child: step.tr().text(13, 19, 400).c(colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

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

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

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

class _CountingPrice extends StatelessWidget {
  const _CountingPrice({
    required this.value,
    required this.suffix,
    required this.style,
  });

  final int value;
  final String suffix;
  final TextStyle style;

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
  const _Price({required this.price, required this.period, this.struck});

  final int price;
  final String period;
  final int? struck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final struck = this.struck;
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
            '${struck.formatPrice()} ${'tf_sum'.tr()}',
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
  const _Radio({required this.selected});

  final bool selected;

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

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.filled});

  final String text;
  final bool filled;

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
