import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/build_context_extensions.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/common/action/actions_page.dart';
import 'package:calora/presentation/common/confirm/confirm_page.dart';
import 'package:calora/presentation/dashboard/features/steps/features/edit/edit_step_goal_page.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/daily_fitness_track_widget.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/leaderboard_section.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/monthly_fitness_track_widget.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/weekly_fitness_track_widget.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class StepsPage extends Managed<StepsManager, StepsState, StepsEffect> {
  StepsPage({super.key});

  final List<ScreenshotController> _screenshotControllers = [
    ScreenshotController(),
    ScreenshotController(),
    ScreenshotController(),
  ];

  final GlobalKey dailyShareAnchorKey = GlobalKey();
  final GlobalKey weeklyShareAnchorKey = GlobalKey();
  final GlobalKey monthlyShareAnchorKey = GlobalKey();

  @override
  Future<void> init(context, manager) async {
    final dailyFuture = manager.fetchDataForPeriod(0, 0, showLoading: true);
    final weeklyFuture = manager.fetchDataForPeriod(1, 0, showLoading: true);
    final monthlyFuture = manager.fetchDataForPeriod(2, 0, showLoading: true);
    await dailyFuture;
    await weeklyFuture;
    await monthlyFuture;
    manager.startLiveSyncIfNeeded();
  }

  @override
  void listener(BuildContext context, StepsManager manager, StepsEffect effect) {
    effect.whenOrNull(
      () => {},
      refreshPagination: (period) {
        switch (period) {
          case 0:
            manager.dailyPaginationService.refresh();
          case 1:
            manager.weeklyPaginationService.refresh();
          case 2:
            manager.monthlyPaginationService.refresh();
        }
      },
    );
  }

  @override
  Widget builder(context, manager, state) {
    final stepValue = state.norms
        .firstWhere(
          (norm) => norm.metric == 'Step',
          orElse: () => NormsRequest(metric: 'Step', value: 0),
        )
        .value;

    final pedometerService = getIt<PedometerService>();

    return Scaffold(
      backgroundColor: context.colors.softGray,
      body: DefaultRefreshIndicator(
        notificationPredicate: (notification) => notification.depth == 1,
        edgeOffset: context.topPadding + kToolbarHeight,
        onRefresh: () async => manager.fetchDataForPeriod(state.period, manager.currentOffset, showLoading: true),
        child: _TabBarWrapper(
          manager: manager,
          state: state,
          stepValue: stepValue,
          pedometerService: pedometerService,
          screenshotControllers: _screenshotControllers,
          dailyShareAnchorKey: dailyShareAnchorKey,
          weeklyShareAnchorKey: weeklyShareAnchorKey,
          monthlyShareAnchorKey: monthlyShareAnchorKey,
          onShowActionsSheet: () => _showActionsSheet(context, manager),
          onShowEditStepGoalSheet: () => _showEditStepGoalSheet(context, manager),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, StepsManager manager) {
    showDialog(
      context: context,
      builder: (dialogContext) => ManagerBuilder<StepsState, StepsEffect>(
        manager: manager,
        properties: (state) => [state.isDeletingUserDailyData],
        builder: (context, state) {
          return ConfirmPage(
            loading: state.isDeletingUserDailyData,
            onCancel: () {},
            onConfirm: () {
              if (!state.isDeletingUserDailyData) {
                dialogContext.router.maybePop();
              }
            },
            confirmText: Strings.rejection,
            cancelText: Strings.cleaning,
            title: Strings.areYouSureDeleteStatistic,
          );
        },
      ),
    );
  }

  void _showEditStepGoalSheet(BuildContext context, StepsManager manager) {
    final stepValue = manager.state.norms
        .firstWhere(
          (norm) => norm.metric == 'Step',
          orElse: () => NormsRequest(metric: 'Step', value: 0),
        )
        .value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditStepGoalPage(
        initialValue: stepValue.toInt(),
        onSave: (value) => manager.updateNorm(NormsRequest(metric: 'Step', value: value.toDouble())),
      ),
    );
  }

  void _showActionsSheet(BuildContext context, StepsManager manager) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String from;
        switch (manager.state.period) {
          case 0:
            from = manager.state.dailyFrom;
            break;
          case 1:
            from = manager.state.weeklyFrom;
            break;
          case 2:
            from = manager.state.monthlyFrom;
            break;
          default:
            return const SizedBox.shrink();
        }

        final fromDate = DateTime.parse(from);

        return ActionsPage(
          onTapDelete:
              manager.state.period == 0 &&
                  DateTime(fromDate.year, fromDate.month, fromDate.day).toIso8601String() ==
                      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String()
              ? () {
                  sheetContext.router.maybePop();
                  _showConfirmDialog(context, manager);
                }
              : null,
          onTapShare: () {
            sheetContext.router.maybePop();
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final image = await _screenshotControllers[manager.state.period].capture();
              if (image == null) return;

              GlobalKey shareAnchorKey;
              switch (manager.state.period) {
                case 0:
                  shareAnchorKey = dailyShareAnchorKey;
                  break;
                case 1:
                  shareAnchorKey = weeklyShareAnchorKey;
                  break;
                case 2:
                  shareAnchorKey = monthlyShareAnchorKey;
                  break;
                default:
                  return;
              }

              final Rect origin = _getWidgetRect(shareAnchorKey);
              final directory = await getTemporaryDirectory();
              final imagePath = await File('${directory.path}/screenshot.png').create();
              await imagePath.writeAsBytes(image);

              await SharePlus.instance.share(
                ShareParams(files: [XFile(imagePath.path)], sharePositionOrigin: origin),
              );
            });
          },
        );
      },
    );
  }

  Rect _getWidgetRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return Offset.zero & Size.zero;

    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero & Size.zero;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return offset & size;
  }
}

class _TabBarWrapper extends StatefulWidget {
  final StepsManager manager;
  final StepsState state;
  final double stepValue;
  final PedometerService pedometerService;
  final List<ScreenshotController> screenshotControllers;
  final GlobalKey dailyShareAnchorKey;
  final GlobalKey weeklyShareAnchorKey;
  final GlobalKey monthlyShareAnchorKey;
  final VoidCallback onShowActionsSheet;
  final VoidCallback onShowEditStepGoalSheet;

  const _TabBarWrapper({
    required this.manager,
    required this.state,
    required this.stepValue,
    required this.pedometerService,
    required this.screenshotControllers,
    required this.dailyShareAnchorKey,
    required this.weeklyShareAnchorKey,
    required this.monthlyShareAnchorKey,
    required this.onShowActionsSheet,
    required this.onShowEditStepGoalSheet,
  });

  @override
  State<_TabBarWrapper> createState() => _TabBarWrapperState();
}

class _TabBarWrapperState extends State<_TabBarWrapper> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.state.period);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    final newPeriod = _tabController.index;

    if (newPeriod == widget.manager.state.period) return;

    widget.manager.changePeriod(newPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(Assets.icons.background.path, fit: BoxFit.fill)),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 42, left: 20, right: 20),
                child: Align(alignment: Alignment.centerLeft, child: Strings.steps.text(32, 36, 700)),
              ),
              const SizedBox(height: 12),
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tabController,
                  indicatorPadding: const EdgeInsets.all(2),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: context.colors.backgroundElevation,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: context.colors.neutralPrimary,
                  unselectedLabelColor: context.colors.neutral600Secondary,
                  tabs: [
                    Tab(child: Strings.daily.text(14, 18, 500)),
                    Tab(child: Strings.weekly.text(14, 18, 500)),
                    Tab(child: Strings.monthly.text(14, 18, 500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildDailyTab(), _buildWeeklyTab(), _buildMonthlyTab()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTab() {
    final isToday = widget.state.period == 0 && widget.state.dailyOffset == 0;

    final shouldShowTodayInitialShimmer = isToday && !widget.state.hasLoadedTodayInitial && widget.state.isDailyLoading;

    final dailyLoading = isToday ? shouldShowTodayInitialShimmer : widget.state.isDailyLoading;

    if (!isToday) {
      final currentSteps = widget.state.dailyDisplayStepCount;

      return _KeepAliveTabContent(
        fitnessTrackWidget: Screenshot(
          controller: widget.screenshotControllers[0],
          child: DailyFitnessTrackWidget(
            key: widget.dailyShareAnchorKey,
            goal: widget.stepValue.toInt(),
            metrics: widget.state.dailyMetrics,
            stepCount: currentSteps,
            offset: widget.state.dailyOffset,
            loading: dailyLoading,
            onClickBackward: () => widget.manager.changeOffset(-1),
            onClickForward: () => widget.manager.changeOffset(1),
            onClickMoreVert: widget.onShowActionsSheet,
            onClickPause: () {},
            onClickEditStepGoal: widget.onShowEditStepGoalSheet,
          ),
        ),
        screenshotController: widget.screenshotControllers[0],
        paginationService: widget.manager.dailyPaginationService,
      );
    }

    return ManagerBuilder<DashboardState, DashboardEffect>(
      manager: context.read<DashboardManager>(),
      properties: (s) => [s.todaySteps],
      builder: (context, dashState) {
        final currentSteps = dashState.todaySteps;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentSteps != widget.manager.state.stepCount) {
            widget.manager.updateTodaySteps(currentSteps);
          }
        });

        // Today's metrics are derived live from the step count so the
        // Soat / Km / Kaloriya figures always match the number on screen
        // and update in real time (backend metrics lag behind the 1-min
        // sync). Falls back to backend metrics if they're already richer.
        final liveMetrics = deriveMetricsFromSteps(currentSteps);

        return _KeepAliveTabContent(
          fitnessTrackWidget: Screenshot(
            controller: widget.screenshotControllers[0],
            child: DailyFitnessTrackWidget(
              key: widget.dailyShareAnchorKey,
              goal: widget.stepValue.toInt(),
              metrics: liveMetrics,
              stepCount: currentSteps, // ✅ mana shu joy
              offset: widget.state.dailyOffset,
              loading: dailyLoading,
              onClickBackward: () => widget.manager.changeOffset(-1),
              onClickForward: () => widget.manager.changeOffset(1),
              onClickMoreVert: widget.onShowActionsSheet,
              onClickPause: () {},
              onClickEditStepGoal: widget.onShowEditStepGoalSheet,
            ),
          ),
          screenshotController: widget.screenshotControllers[0],
          paginationService: widget.manager.dailyPaginationService,
        );
      },
    );
  }

  Widget _buildWeeklyTab() {
    final weeklyLoading =
        widget.state.isWeeklyLoading || (widget.state.period == 1 && widget.state.weeklySteps.isEmpty);

    return _KeepAliveTabContent(
      fitnessTrackWidget: Screenshot(
        controller: widget.screenshotControllers[1],
        child: WeeklyFitnessTrackWidget(
          key: widget.weeklyShareAnchorKey,
          primaryValues: widget.state.weeklyPrimaryValues,
          goal: widget.stepValue.toInt(),
          metrics: widget.state.weeklyMetrics,
          offset: widget.state.weeklyOffset,
          loading: weeklyLoading,
          onClickBackward: () => widget.manager.changeOffset(-1),
          onClickForward: () => widget.manager.changeOffset(1),
          onClickMoreVert: widget.onShowActionsSheet,
          onClickPause: () {},
        ),
      ),
      screenshotController: widget.screenshotControllers[1],
      paginationService: widget.manager.weeklyPaginationService,
    );
  }

  Widget _buildMonthlyTab() {
    final monthlyLoading =
        widget.state.isMonthlyLoading || (widget.state.period == 2 && widget.state.monthlySteps.isEmpty);

    return _KeepAliveTabContent(
      fitnessTrackWidget: Screenshot(
        controller: widget.screenshotControllers[2],
        child: MonthlyFitnessTrackWidget(
          key: widget.monthlyShareAnchorKey,
          primaryValues: widget.state.monthlyPrimaryValues,
          goal: widget.stepValue.toInt(),
          metrics: widget.state.monthlyMetrics,
          offset: widget.state.monthlyOffset,
          loading: monthlyLoading,
          onClickBackward: () => widget.manager.changeOffset(-1),
          onClickForward: () => widget.manager.changeOffset(1),
          onClickMoreVert: widget.onShowActionsSheet,
          onClickPause: () {},
        ),
      ),
      screenshotController: widget.screenshotControllers[2],
      paginationService: widget.manager.monthlyPaginationService,
    );
  }
}

class _KeepAliveTabContent extends StatefulWidget {
  const _KeepAliveTabContent({
    required this.fitnessTrackWidget,
    required this.screenshotController,
    required this.paginationService,
  });

  final Widget fitnessTrackWidget;
  final ScreenshotController screenshotController;
  final PaginationService<UserStatRequest> paginationService;

  @override
  State<_KeepAliveTabContent> createState() => _KeepAliveTabContentState();
}

class _KeepAliveTabContentState extends State<_KeepAliveTabContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: widget.fitnessTrackWidget),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: LeaderboardSection(paginationService: widget.paginationService),
        ),
      ],
    );
  }
}
