import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/premium_sheet.dart';
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
/// UI ONLY — prices are fixed here, not loaded from the backend. "Continue"
/// on monthly / yearly opens the real [PremiumSheet] (backend plans and
/// payment); the family plan has no backend yet, so it only says "soon".
@RoutePage()
class TariffsPage extends StatefulWidget {
  const TariffsPage({super.key});

  static const monthlyPrice = 49000;
  static const yearlyPrice = 399000;

  /// Family plan: two people for 70 000 a month instead of 2 × 49 000.
  static const familyPrice = 70000;
  static const familySize = 2;

  @override
  State<TariffsPage> createState() => _TariffsPageState();
}

class _TariffsPageState extends State<TariffsPage>
    with SingleTickerProviderStateMixin {
  _Tariff _selected = _Tariff.yearly;

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

  int get _price => switch (_selected) {
    _Tariff.monthly => TariffsPage.monthlyPrice,
    _Tariff.yearly => TariffsPage.yearlyPrice,
    _Tariff.family => TariffsPage.familyPrice,
  };

  int get _yearlySavePercent =>
      (100 - TariffsPage.yearlyPrice * 100 / (TariffsPage.monthlyPrice * 12))
          .round();

  void _continue() {
    if (_selected == _Tariff.family) {
      CustomSnackBar.showInfo(context, 'tf_family_soon'.tr());
      return;
    }
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PremiumSheet(),
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
                _reveal(
                  2,
                  _PlanTile(
                    selected: _selected == _Tariff.yearly,
                    onTap: () => setState(() => _selected = _Tariff.yearly),
                    title: 'tf_yearly'.tr(),
                    tag: 'tf_best_value'.tr(
                      namedArgs: {'percent': '$_yearlySavePercent'},
                    ),
                    tagFilled: true,
                    subtitle: 'tf_yearly_sub'.tr(
                      namedArgs: {
                        // Non-breaking separator keeps "33 250" on one line.
                        'price': (TariffsPage.yearlyPrice / 12).formatPrice(
                          separator: ' ',
                        ),
                      },
                    ),
                    price: TariffsPage.yearlyPrice,
                    period: 'tf_per_year'.tr(),
                    struckPrice: TariffsPage.monthlyPrice * 12,
                  ),
                ),
                const SizedBox(height: 12),
                _reveal(
                  3,
                  _PlanTile(
                    selected: _selected == _Tariff.monthly,
                    onTap: () => setState(() => _selected = _Tariff.monthly),
                    title: 'tf_monthly'.tr(),
                    subtitle: 'tf_monthly_sub'.tr(),
                    price: TariffsPage.monthlyPrice,
                    period: 'tf_per_month'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                _reveal(
                  4,
                  _FamilyCard(
                    selected: _selected == _Tariff.family,
                    onTap: () => setState(() => _selected = _Tariff.family),
                  ),
                ),
                const SizedBox(height: 28),
                _reveal(5, _included(context)),
                const SizedBox(height: 20),
                _reveal(6, _assurances(context)),
              ],
            ),
          ),
          _bottomBar(context),
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
                onPressed: _continue,
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

  const _FamilyCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const price = TariffsPage.familyPrice;

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
                _Price(price: price, period: 'tf_per_month'.tr()),
              ],
            ),
            const SizedBox(height: 16),
            _FamilyPriceCompare(active: selected),
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
/// Top row: two people, each in their own box with their own 49 000 — two
/// separate subscriptions. Bottom row: the same two people inside ONE box at
/// 35 000 each — one shared subscription. Both rows share the same column
/// geometry, so each person's price drop reads straight down the column.
///
/// Plays once, the first time it is (almost) fully on screen (or when the family plan
/// is picked): the separate plans settle in, the two people move together
/// into the shared box while their price counts down 49 000 → 35 000, and
/// the monthly saving lands last.
class _FamilyPriceCompare extends StatefulWidget {
  /// The family plan is selected — starts the story if it hasn't run yet.
  final bool active;

  const _FamilyPriceCompare({required this.active});

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
    const single = TariffsPage.monthlyPrice;
    const separate = single * TariffsPage.familySize;
    const family = TariffsPage.familyPrice;
    const each = family ~/ TariffsPage.familySize;
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
        ? (const Color(0xFFFCE9D2), const Color(0xFFD9822B))
        : (colors.accentSub, colors.white);

    return Row(
      children: [
        _Avatar(size: 30, background: bg, foreground: fg),
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

/// Neutral person silhouette in a circle — head and shoulders, no face.
class _Avatar extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  const _Avatar({
    required this.size,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _AvatarPainter(background, foreground),
  );
}

class _AvatarPainter extends CustomPainter {
  final Color background;
  final Color foreground;

  const _AvatarPainter(this.background, this.foreground);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final circle = Path()..addOval(Offset.zero & size);
    canvas.drawPath(circle, Paint()..color = background);

    canvas.save();
    canvas.clipPath(circle);
    final fill = Paint()..color = foreground;
    canvas.drawCircle(Offset(d * 0.5, d * 0.39), d * 0.17, fill);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(d * 0.5, d * 0.98),
        width: d * 0.66,
        height: d * 0.56,
      ),
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.background != background || old.foreground != foreground;
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
