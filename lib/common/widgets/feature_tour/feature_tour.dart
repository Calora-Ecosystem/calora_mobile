import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bridges the dashboard tour to the active [TabsRouter] so a step can switch
/// to the section it is describing. Only used by the dashboard walkthrough.
class DashboardTabAccess {
  DashboardTabAccess._();
  static TabsRouter? router;
}

/// Global spotlight anchors for the first-run dashboard walkthrough.
///
/// These keys are attached to the **real** controls inside the tab pages —
/// the Home "Add food" button, the first course card, the Steps period tabs —
/// so the tour highlights exactly what the user will tap, not just the tiny
/// bottom-nav cell. Because [GlobalKey]s resolve across the whole widget tree,
/// the dashboard-level tour host can spotlight a widget that lives deep inside
/// a child tab page.
class TourAnchors {
  TourAnchors._();

  /// The green "Ovqat qo'shish" button on the Home tab (`DailyFeedRateWidget`).
  static final GlobalKey homeAddFood = GlobalKey(debugLabel: 'tour_home_add_food');

  /// The first course card on the Course tab.
  static final GlobalKey courseFirst = GlobalKey(debugLabel: 'tour_course_first');

  /// The Daily/Weekly/Monthly period selector on the Steps tab.
  static final GlobalKey stepsPeriod = GlobalKey(debugLabel: 'tour_steps_period');

  /// The green "Scan your food" banner on the Home tab.
  static final GlobalKey homeScanBanner = GlobalKey(debugLabel: 'tour_home_banner');

  /// The swipeable week calendar at the top of the Calories tab.
  static final GlobalKey caloriesCalendar = GlobalKey(debugLabel: 'tour_calories_calendar');

  /// The four meal cards (breakfast/lunch/snack/dinner) on the Calories tab.
  static final GlobalKey caloriesMeals = GlobalKey(debugLabel: 'tour_calories_meals');

  /// The profile header card on the Profile tab.
  static final GlobalKey profileMain = GlobalKey(debugLabel: 'tour_profile_main');
}

/// Handle to a running overlay tour so the caller can dismiss it early — e.g.
/// if the host sheet is closed before the tour finishes.
class FeatureTourOverlayHandle {
  OverlayEntry? _entry;
  bool _dismissed = false;

  void _bind(OverlayEntry e) => _entry = e;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _entry?.remove();
    _entry = null;
  }
}

/// Runs a coach-mark tour in the **root overlay** (full-screen) instead of
/// inside a single page. Use this for tours that must spotlight widgets living
/// inside a modal bottom sheet, where a page-local [FeatureTourHost] would
/// mis-align its spotlight (its scrim would only cover the sheet, not the whole
/// screen the target coordinates are measured against).
///
/// Shows at most once per [tourId]. Returns a handle to dismiss it early, or
/// null if it was already shown / there are no steps.
FeatureTourOverlayHandle? showFeatureTourOverlay(
  BuildContext context, {
  required String tourId,
  required List<FeatureTourStep> steps,
}) {
  if (StepLedgerStore().isTourShown(tourId) || steps.isEmpty) return null;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  final handle = FeatureTourOverlayHandle();
  final entry = OverlayEntry(
    builder: (_) => _FeatureTourView(
      steps: steps,
      itemCount: 5,
      switchTabs: false,
      onClose: () {
        StepLedgerStore().setTourShown(tourId);
        handle.dismiss();
      },
    ),
  );
  handle._bind(entry);
  overlay.insert(entry);
  return handle;
}

/// A detail bullet shown inside a tour card. [icon] is a pre-sized (~16px)
/// widget so callers can pass a Material `Icon` or a real app SVG asset —
/// matching exactly what the user sees in the app.
class FeatureTourBullet {
  final Widget icon;
  final String text;
  const FeatureTourBullet(this.icon, this.text);
}

/// A single stop on a coach-mark tour.
///
/// Provide **either**:
/// * [targetKey] — spotlight a real on-screen widget (per-page button tours), or
/// * [navIndex]  — spotlight a bottom-nav cell geometrically (dashboard tour).
class FeatureTourStep {
  final GlobalKey? targetKey;
  final int? navIndex;
  final IconData icon;
  final String title;
  final String description;
  final List<FeatureTourBullet> bullets;

  const FeatureTourStep({
    required this.icon,
    required this.title,
    required this.description,
    this.targetKey,
    this.navIndex,
    this.bullets = const [],
  });
}

/// Wraps a page and, on its first visit, overlays a coach-mark tour that
/// darkens the screen and spotlights each real button / section in turn.
///
/// Rendered as a `Stack` sibling above [child] (not via the `Overlay` API),
/// so it is immune to overlay lifecycle races and always renders on top.
class FeatureTourHost extends StatefulWidget {
  final Widget child;
  final List<FeatureTourStep> steps;

  /// Persistence id — distinguishes this tour from others (e.g. `dashboard`,
  /// `add_food`). Shown only once per id.
  final String tourId;

  /// Number of bottom-nav cells (only used for [FeatureTourStep.navIndex]).
  final int itemCount;

  /// Dashboard tour drives the active tab as it walks sections.
  final bool switchTabs;

  /// Delay before the tour fades in, letting the page settle first.
  final Duration delay;

  const FeatureTourHost({
    super.key,
    required this.child,
    required this.steps,
    required this.tourId,
    this.itemCount = 5,
    this.switchTabs = false,
    this.delay = const Duration(milliseconds: 600),
  });

  @override
  State<FeatureTourHost> createState() => _FeatureTourHostState();
}

class _FeatureTourHostState extends State<FeatureTourHost> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (StepLedgerStore().isTourShown(widget.tourId) || widget.steps.isEmpty) {
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _finish() {
    StepLedgerStore().setTourShown(widget.tourId);
    if (widget.switchTabs) DashboardTabAccess.router?.setActiveIndex(0);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: _FeatureTourView(
              steps: widget.steps,
              itemCount: widget.itemCount,
              switchTabs: widget.switchTabs,
              onClose: _finish,
            ),
          ),
      ],
    );
  }
}

class _FeatureTourView extends StatefulWidget {
  final List<FeatureTourStep> steps;
  final int itemCount;
  final bool switchTabs;
  final VoidCallback onClose;

  const _FeatureTourView({
    required this.steps,
    required this.itemCount,
    required this.switchTabs,
    required this.onClose,
  });

  @override
  State<_FeatureTourView> createState() => _FeatureTourViewState();
}

class _FeatureTourViewState extends State<_FeatureTourView>
    with TickerProviderStateMixin {
  int _index = 0;
  bool _closing = false;

  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyTab());
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _applyTab() {
    if (!widget.switchTabs) return;
    final router = DashboardTabAccess.router;
    final target = widget.steps[_index].navIndex;
    if (router != null && target != null && router.activeIndex != target) {
      router.setActiveIndex(target);
    }
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _close();
      return;
    }
    setState(() => _index++);
    _applyTab();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _fade.reverse();
    if (mounted) widget.onClose();
  }

  /// Spotlight rect for step [i]: a real widget via its [GlobalKey], or a
  /// bottom-nav cell computed geometrically. Returns null when a keyed target
  /// hasn't been laid out yet.
  Rect? _rectFor(int i, Size size, EdgeInsets pad) {
    final step = widget.steps[i];
    final key = step.targetKey;
    if (key != null) {
      final ctx = key.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft = box.localToGlobal(Offset.zero);
      return (topLeft & box.size).inflate(8);
    }
    final nav = step.navIndex;
    if (nav != null) {
      const barH = kBottomNavigationBarHeight;
      final top = size.height - pad.bottom - barH;
      final itemW = size.width / widget.itemCount;
      final center = Offset(itemW * (nav + 0.5), top + barH / 2);
      return Rect.fromCenter(center: center, width: 66, height: 56);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final pad = mq.padding;
    final step = widget.steps[_index];

    final rect = _rectFor(_index, size, pad);
    // Target not laid out yet — retry next frame.
    if (rect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    final spot = rect ??
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 0,
            height: 0);
    final rrect = RRect.fromRectAndRadius(spot, const Radius.circular(16));

    // Place the card on the side of the spotlight with more room.
    final bool targetLow = spot.center.dy > size.height * 0.5;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(
                  painter: _ScrimPainter(
                    hole: rrect,
                    scrim: Colors.black.withValues(alpha: 0.68),
                    ring: context.colors.white.withValues(alpha: 0.95),
                    drawHole: rect != null,
                  ),
                ),
              ),
            ),
            if (targetLow)
              Positioned(
                left: 16,
                right: 16,
                bottom: size.height - spot.top + 14,
                child: _card(context, step),
              )
            else
              Positioned(
                left: 16,
                right: 16,
                top: spot.bottom + 14,
                child: _card(context, step),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, FeatureTourStep step) {
    final accent = context.colors.accentSub;
    final isLast = _index == widget.steps.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_index),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: context.colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, context.colors.accentLightSub],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(step.icon, size: 22, color: context.colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: step.title
                      .text(17, 22, 700)
                      .c(context.colors.textStrong)
                      .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            step.description.text(14, 20, 400).c(context.colors.textSub),
            if (step.bullets.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final b in step.bullets) _bullet(context, b),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _dots(context, accent),
                const Spacer(),
                if (!isLast)
                  GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: 'ft_skip'
                          .tr()
                          .text(13, 16, 600)
                          .c(context.colors.textSub),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.black, 0.14)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.34),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        (isLast ? 'ft_done' : 'ft_next')
                            .tr()
                            .text(14, 18, 700)
                            .c(context.colors.white),
                        const SizedBox(width: 6),
                        Icon(
                          isLast
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: context.colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, FeatureTourBullet b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: b.icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: b.text.text(13, 17, 500).c(context.colors.textStrong),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.steps.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 5),
            width: i == _index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _index ? accent : context.colors.strokeSub,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final RRect hole;
  final Color scrim;
  final Color ring;
  final bool drawHole;

  _ScrimPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
    required this.drawHole,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawHole) {
      canvas.drawRect(Offset.zero & size, Paint()..color = scrim);
      return;
    }
    final full = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRRect(hole);
    final scrimPath = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(scrimPath, Paint()..color = scrim);
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole ||
      old.scrim != scrim ||
      old.ring != ring ||
      old.drawHole != drawHole;
}
