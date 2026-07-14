import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/calendar/calendar_selector_widget.dart';
import 'package:calora/common/widgets/feature_tour/feature_tour.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_manager.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:calora/widgets/meals/meal_time_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:calora/widgets/app_bar/home_app_bar.dart' show HomeAppBar;
import 'package:calora/widgets/home/daily_feed_rate_widget.dart';
import 'package:calora/widgets/plan/daily_plan_widget.dart';
import 'package:calora/widgets/steps/step_card_widget.dart';
import 'package:calora/widgets/water/water_intake_selector.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class HomePage extends Managed<HomeManager, HomeState, HomeEffect> {
  HomePage({super.key});

  TabsRouter? _tabsRouter;
  int _lastIndex = 0;

  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  @override
  void init(BuildContext context, HomeManager manager) {
    manager.updateDay(DateTime.now());
    manager.refreshAll();
    // Permissions and step-tracking init are front-loaded by DashboardPage via
    // PermissionBootstrap (all permission dialogs first, then the tour).
    _tabsRouter = AutoTabsRouter.of(context);
    _lastIndex = _tabsRouter!.activeIndex;
    _tabsRouter!.addListener(() {
      final idx = _tabsRouter!.activeIndex;
      if (_lastIndex != 0 && idx == 0) {
        manager.refreshAll();
      }
      _lastIndex = idx;
    });
  }

  @override
  void listener(BuildContext context, HomeManager manager, HomeEffect effect) {
    super.listener(context, manager, effect);
    effect.when(
      forceUpdate: () => context.router.replaceAll([const ForceUpdateRoute()]),
    );
  }

  @override
  Widget builder(BuildContext context, HomeManager manager, HomeState state) {
    return FeatureTourHost(
      tourId: 'tour_home',
      steps: _homeTourSteps(context),
      child: StreamBuilder<ProfileRequest>(
        stream: profileStore.watch(),
        builder: (context, snapshot) {
          return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Assets.icons.background.image(fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isScrolled,
                      builder: (context, scrolled, _) {
                        return HomeAppBar(
                          isScrolled: scrolled,
                          profile: snapshot.data,
                          unreadCount: state.unreadCount,
                          onTabNotification: () => openInbox(context),
                        );
                      },
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          _isScrolled.value = notification.metrics.pixels > 10;
                          return false;
                        },
                        child: DefaultRefreshIndicator(
                          onRefresh: () async => manager.refreshAll(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              spacing: 16,
                              children: [
                                DailyPlanWidget(
                                  onDateTap: () => openCalendar(context, manager),
                                  loading: state.isLoading,
                                  onBackward: () {
                                    final newDay = (state.day ?? DateTime.now()).subtract(
                                      const Duration(days: 1),
                                    );
                                    manager.updateDay(newDay);
                                    manager.getSummary();
                                    manager.getWater();
                                  },
                                  onForward: () {
                                    final newDay = (state.day ?? DateTime.now()).add(
                                      const Duration(days: 1),
                                    );
                                    manager.updateDay(newDay);
                                    manager.getSummary();
                                    manager.getWater();
                                  },
                                  date: state.day ?? DateTime.now(),
                                  calories:
                                      '${state.targetKcal.asFixedTruncated(0)} ${Strings.kcal}',
                                  water:
                                      '${(state.targetLiters / 1000).asFixedTruncated(2)} ${Strings.liter}',
                                  steps: state.targetSteps.toString(),
                                ),
                                GestureDetector(
                                  onTap: () => _onScanTap(context, manager),
                                  child: Container(
                                    key: TourAnchors.homeScanBanner,
                                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const RadialGradient(
                                        radius: 1.5,
                                        center: Alignment(0.7, 0),
                                        colors: [Color(0xFFECFFEF), Color(0xFF58AE8A)],
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            spacing: 8,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: context.colors.white
                                                      .withValues(alpha: 0.22),
                                                  borderRadius:
                                                      BorderRadius.circular(100),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  spacing: 6,
                                                  children: [
                                                    Assets.icons.icScan.svg(
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter: ColorFilter.mode(
                                                        context.colors.white,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                    'home_scan_badge'
                                                        .tr()
                                                        .text(12, 14, 600)
                                                        .c(context.colors.white),
                                                  ],
                                                ),
                                              ),
                                              'home_scan_title'
                                                  .tr()
                                                  .text(22, 28, 700)
                                                  .c(context.colors.white),
                                              'home_scan_subtitle'
                                                  .tr()
                                                  .text(14, 18, 500)
                                                  .c(context.colors.white),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const _ScanBannerArt(),
                                      ],
                                    ),
                                  ),
                                ),
                                DailyFeedRateWidget(
                                  addFoodButtonKey: TourAnchors.homeAddFood,
                                  onAddFoodTap: () => openCaloriesPage(context),
                                  normCalories: (state.summary?.kcalNorm.value ?? 0)
                                      .asFixedTruncated(0)
                                      .toString(),
                                  nutrients: state.nutrients,
                                  progressPercent:
                                      (state.summary?.sum.Kcal ?? 0) /
                                      (state.summary?.kcalNorm.value ?? 0),
                                  remainedCalories:
                                      (state.summary?.kcalNorm.value ?? 0) -
                                      (state.summary?.sum.Kcal ?? 0),
                                  loading: state.isSummaryLoading,
                                ),
                                _buildStepCard(
                                  context: context,
                                  state: state,
                                  manager: manager,
                                ),
                                WaterIntakeSelector(
                                  loading: state.isWaterLoading,
                                  date: state.day ?? DateTime.now(),
                                  onCountChanged: (count) {
                                    manager.updateWaterIntake(count * 0.25);
                                    manager.postWater();
                                  },
                                  bottleCapacity: state.bottleCapacity,
                                  targetLiters: state.targetLiters,
                                  currentIntake: state.waterIntake,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  /// First-visit coach-mark for the Home tab: explains only the scan banner
  /// (and the meal-time sheet it opens). The add-food button is intentionally
  /// not spotlighted here.
  List<FeatureTourStep> _homeTourSteps(BuildContext context) {
    return [
      FeatureTourStep(
        targetKey: TourAnchors.homeScanBanner,
        icon: Icons.center_focus_strong_rounded,
        title: 'ft_banner_t'.tr(),
        description: 'ft_banner_d'.tr(),
      ),
    ];
  }

  /// Step card — `DashboardManager.todaySteps`'dan ko'rsatadi (Health/Pedometer farqi
  /// ko'rinmaydi, chunki DashboardManager `max(health, pedometer)`'ni beradi).
  Widget _buildStepCard({
    required BuildContext context,
    required HomeState state,
    required HomeManager manager,
  }) {
    final selectedDay = state.day ?? DateTime.now();
    final isToday = _isToday(selectedDay);

    // Bugungi kun bo'lmasa — backend'dan kelgan qiymatni ko'rsatamiz
    if (!isToday) {
      return StepCardWidget(
        loading: state.isMetricsLoading,
        currentSteps: state.currentSteps,
        targetSteps: state.targetSteps,
        timeInSeconds: state.metrics?.duration ?? 0,
        distanceInKm: state.metrics?.distance ?? 0,
        caloriesBurned: state.metrics?.kcal ?? 0,
      );
    }

    // Bugungi kun — DashboardManager'dan live qadam oladi
    return ManagerBuilder<DashboardState, DashboardEffect>(
      manager: context.read<DashboardManager>(),
      properties: (s) => [s.todaySteps],
      builder: (context, dashState) {
        return StepCardWidget(
          loading: false,
          currentSteps: dashState.todaySteps,
          targetSteps: state.targetSteps,
          timeInSeconds: state.metrics?.duration ?? 0,
          distanceInKm: state.metrics?.distance ?? 0,
          caloriesBurned: state.metrics?.kcal ?? 0,
        );
      },
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return now.year == day.year && now.month == day.month && now.day == day.day;
  }

  /// Home "Scan food / calculate calories" banner tap. Opens the meal sheet
  /// (per-meal cards with consumed kcal). Picking a meal opens that meal's
  /// detail page with the add-food screen on top — so adding food success
  /// returns to the meal's logged-foods list, and backing out of that list
  /// lands back here on Home.
  Future<void> _onScanTap(BuildContext context, HomeManager manager) async {
    final pick = await showMealTimePicker(context);
    if (pick == null || !context.mounted) return;

    await context.router.push(
      MealsRoute(
        type: pick.type,
        dateTime: pick.date,
        categoryId: 1,
        openAddOnEnter: true,
      ),
    );
    manager.refreshAll();
  }

  void openCalendar(BuildContext context, HomeManager manager) {
    context.showAppBottomSheet(
      child: CalendarSelectorWidget(
        initialDate: manager.state.day ?? DateTime.now(),
        onDaySelected: (date) {
          manager.updateDay(date);
          manager.getSummary();
          manager.getWater();
        },
      ),
    );
  }

  void openCaloriesPage(BuildContext context) {
    context.router.navigate(const CaloriesRoute());
  }

  void openCaloraAi(BuildContext context) {
    context.router.navigate(const CaloraAiRoute());
  }

  void openInbox(BuildContext context) async {
    context.router.navigate(const InboxRoute());
    final token = await FirebaseMessaging.instance.getToken();
  }
}

/// The Home "Scan food" banner artwork: a real dish photo with a live scan
/// overlay. A glowing green beam sweeps across the food and the corner
/// brackets breathe, so it reads instantly as "this meal is being scanned" —
/// no device frame needed. Uses an existing food asset (no external downloads),
/// framed cleanly to sit on the green banner.
class _ScanBannerArt extends StatefulWidget {
  const _ScanBannerArt();

  @override
  State<_ScanBannerArt> createState() => _ScanBannerArtState();
}

class _ScanBannerArtState extends State<_ScanBannerArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _size = 104;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accentSub;

    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final wave = (1 - math.cos(t * 2 * math.pi)) / 2; // 0 → 1 → 0
          final floatY = math.sin(t * 2 * math.pi) * 1.5;
          // Scan sweeps top → bottom → top through the centre of the dish.
          final scanCenter = 10 + (_size - 20) * wave;

          return Transform.translate(
            offset: Offset(0, floatY),
            child: SizedBox(
              width: _size,
              height: _size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The salad plate, cut out onto a transparent background so
                  // the green banner shows straight through behind it. A soft
                  // shadow lifts the dish off the banner.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/scan_food.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Scan beam is clipped to the round plate so it only sweeps
                  // across the food, never the empty banner around it.
                  ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Soft scanning band sweeping top → bottom → top.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: scanCenter - 11,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  accent.withValues(alpha: 0),
                                  accent.withValues(alpha: 0.28),
                                  accent.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bright scan line: white core with a green glow.
                        Positioned(
                          left: 4,
                          right: 4,
                          top: scanCenter - 1.5,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0),
                                  Colors.white,
                                  accent.withValues(alpha: 0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Viewfinder corner brackets framing the dish as a live scan
                  // target. They breathe in sync with the sweeping beam so the
                  // frame reads as "locking on" without covering the food.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanBracketsPainter(
                        color: Colors.white,
                        glow: accent,
                        pulse: wave,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Draws four L-shaped viewfinder brackets, one per corner, with rounded
/// elbows and a soft accent glow. [pulse] (0→1→0) gently eases the brackets
/// inward and lifts their opacity so the frame "breathes" with the scan beam.
class _ScanBracketsPainter extends CustomPainter {
  const _ScanBracketsPainter({
    required this.color,
    required this.glow,
    required this.pulse,
  });

  final Color color;
  final Color glow;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 17.0; // length of each bracket leg
    const stroke = 2.5;
    final inset = 2.0 + pulse * 3.5; // breathe inward as the beam passes
    final opacity = 0.7 + pulse * 0.3;

    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void corner(double cx, double cy, double sx, double sy) {
      final path = Path()
        ..moveTo(cx + sx * arm, cy)
        ..lineTo(cx, cy)
        ..lineTo(cx, cy + sy * arm);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    corner(inset, inset, 1, 1); // top-left
    corner(size.width - inset, inset, -1, 1); // top-right
    corner(inset, size.height - inset, 1, -1); // bottom-left
    corner(size.width - inset, size.height - inset, -1, -1); // bottom-right
  }

  @override
  bool shouldRepaint(_ScanBracketsPainter old) =>
      old.pulse != pulse || old.color != color || old.glow != glow;
}
