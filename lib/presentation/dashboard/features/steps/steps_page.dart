import 'dart:developer';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/build_context_extensions.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
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

  TabController? _tabController;
  bool _tabListenerAttached = false;

  @override
  void init(context, manager) {
    manager.fetchDataForPeriod(0, 0, showLoading: true);
    manager.fetchDataForPeriod(1, 0);
    manager.fetchDataForPeriod(2, 0);
    manager.startLiveSyncIfNeeded();

    context.read<DashboardManager>().initialize();
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
        onRefresh: () async => manager.fetchDataForPeriod(
          state.period,
          manager.currentOffset,
          showLoading: true,
        ),
        child: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context);

              if (_tabController != controller || !_tabListenerAttached) {
                _tabController = controller;
                _tabListenerAttached = true;
                controller.addListener(() {
                  if (controller.indexIsChanging) return;
                  final newPeriod = controller.index;
                  manager.changePeriod(newPeriod);
                  int offset = 0;
                  if (newPeriod == 0) offset = manager.state.dailyOffset;
                  if (newPeriod == 1) offset = manager.state.weeklyOffset;
                  if (newPeriod == 2) offset = manager.state.monthlyOffset;
                  if (offset == 0) {
                    manager.fetchDataForPeriod(newPeriod, offset);
                  }
                });
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(Assets.icons.background.path, fit: BoxFit.fill),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 42, left: 20, right: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Strings.steps.text(32, 36, 700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
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
                            children: [
                              _buildDailyTabWithStream(
                                context: context,
                                pedometerService: pedometerService,
                                manager: manager,
                                state: state,
                                stepValue: stepValue,
                              ),
                              _buildTabContent(
                                screenshotController: _screenshotControllers[1],
                                fitnessTrackWidget: WeeklyFitnessTrackWidget(
                                  key: weeklyShareAnchorKey,
                                  primaryValues: state.weeklyPrimaryValues,
                                  goal: stepValue.toInt(),
                                  metrics: state.weeklyMetrics,
                                  offset: state.weeklyOffset,
                                  loading: state.isWeeklyLoading,
                                  onClickBackward: () => manager.changeOffset(-1),
                                  onClickForward: () => manager.changeOffset(1),
                                  onClickMoreVert: () => _showActionsSheet(context, manager),
                                  onClickPause: () {},
                                ),
                                allUserStatsForPeriod: state.weeklyUserStates,
                                isGettingStats: state.isWeeklyLoading,
                              ),
                              _buildTabContent(
                                screenshotController: _screenshotControllers[2],
                                fitnessTrackWidget: MonthlyFitnessTrackWidget(
                                  key: monthlyShareAnchorKey,
                                  primaryValues: state.monthlyPrimaryValues,
                                  goal: stepValue.toInt(),
                                  metrics: state.monthlyMetrics,
                                  offset: state.monthlyOffset,
                                  loading: state.isMonthlyLoading,
                                  onClickBackward: () => manager.changeOffset(-1),
                                  onClickForward: () => manager.changeOffset(1),
                                  onClickMoreVert: () => _showActionsSheet(context, manager),
                                  onClickPause: () {},
                                ),
                                allUserStatsForPeriod: state.monthlyUserStates,
                                isGettingStats: state.isMonthlyLoading,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTabWithStream({
    required BuildContext context,
    required PedometerService pedometerService,
    required StepsManager manager,
    required StepsState state,
    required double stepValue,
  }) {
    final isToday = state.period == 0 && state.dailyOffset == 0;

    final currentSteps = isToday ? state.stepCount : state.dailyDisplayStepCount;

    final shouldShowTodayInitialShimmer = isToday && !state.hasLoadedTodayInitial && state.isDailyLoading;

    return _buildTabContent(
      screenshotController: _screenshotControllers[0],
      fitnessTrackWidget: DailyFitnessTrackWidget(
        key: dailyShareAnchorKey,
        goal: stepValue.toInt(),
        metrics: state.dailyMetrics,
        stepCount: currentSteps,
        offset: state.dailyOffset,
        loading: isToday ? shouldShowTodayInitialShimmer : state.isDailyLoading,
        onClickBackward: () => manager.changeOffset(-1),
        onClickForward: () => manager.changeOffset(1),
        onClickMoreVert: () => _showActionsSheet(context, manager),
        onClickPause: () {},
        onClickEditStepGoal: () => _showEditStepGoalSheet(context, manager),
      ),
      allUserStatsForPeriod: state.dailyUserStates,
      isGettingStats: state.isDailyLoading,
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
        onSave: (value) => manager.updateNorm(
          NormsRequest(metric: 'Step', value: value.toDouble()),
        ),
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

  Widget _buildTabContent({
    required Widget fitnessTrackWidget,
    required ScreenshotController screenshotController,
    required List<UserStatRequest> allUserStatsForPeriod,
    required bool isGettingStats,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Screenshot(controller: screenshotController, child: fitnessTrackWidget),
          LeaderboardSection(
            allUserStatsForPeriod: allUserStatsForPeriod,
            isGettingStats: isGettingStats,
          ),
        ],
      ),
    );
  }
}
