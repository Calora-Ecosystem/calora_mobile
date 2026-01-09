import 'dart:developer';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
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
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class StepsPage extends Managed<StepsManager, StepsState, StepsEffect> with WidgetsBindingObserver {
  StepsPage({super.key});

  late PedometerService _pedometerService;
  final List<ScreenshotController> _screenshotControllers = [
    ScreenshotController(),
    ScreenshotController(),
    ScreenshotController(),
  ];
  int _previousTabIndex = 0;
  final GlobalKey dailyShareAnchorKey = GlobalKey();
  final GlobalKey weeklyShareAnchorKey = GlobalKey();
  final GlobalKey monthlyShareAnchorKey = GlobalKey();

  @override
  void init(context, manager) {
    WidgetsBinding.instance.addObserver(this);
    manager.getNorms();
    manager.startPeriodicDataSync();
    manager.fetchDataForPeriod(0, 0);
    manager.fetchDataForPeriod(1, 0);
    manager.fetchDataForPeriod(2, 0);
    _initializePedometerService(manager);
  }

  @override
  void onFocusGained(BuildContext context, StepsManager manager) {
    super.onFocusGained(context, manager);
    manager.startPeriodicDataSync();
    log('gaining focus');
  }

  @override
  void onFocusLost(BuildContext context, StepsManager manager) {
    super.onFocusLost(context, manager);
    manager.stopPeriodicDataSync();
    log('loosing focus');
  }

  void _initializePedometerService(StepsManager manager) async {
    _pedometerService = PedometerService(
      onTodayStepCountUpdated: (todaySteps) => manager.updateTodaySteps(todaySteps),
      onError: (error) => debugPrint('StepsPageError: $error'),
    );
    await _pedometerService.initializePedometer();
  }

  @override
  Widget builder(context, manager, state) {
    final stepValue = state.norms
        .firstWhere(
          (norm) => norm.metric == 'Step',
          orElse: () => NormsRequest(metric: 'Step', value: 0),
        )
        .value;
    return Scaffold(
      backgroundColor: context.colors.softGray,
      body: DefaultRefreshIndicator(
        notificationPredicate: (notification) => notification.depth == 1,
        edgeOffset: context.topPadding + kToolbarHeight,
        onRefresh: () async => await manager.fetchDataForPeriod(state.period, manager.currentOffset, refresh: true),
        child: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              tabController.addListener(() {
                if (!tabController.indexIsChanging && tabController.index != _previousTabIndex) {
                  _previousTabIndex = tabController.index;
                  manager.changePeriod(tabController.index);
                }
              });
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
                            children:
                                [
                                      DailyFitnessTrackWidget(
                                        key: dailyShareAnchorKey,
                                        goal: stepValue.toInt(),
                                        metrics: state.dailyMetrics,
                                        stepCount: state.dailyDisplayStepCount,
                                        offset: state.dailyOffset,
                                        onClickBackward: () => manager.changeOffset(-1),
                                        onClickForward: () => manager.changeOffset(1),
                                        onClickMoreVert: () => _showActionsSheet(context, manager),
                                        onClickPause: () {},
                                        onClickEditStepGoal: () => _showEditStepGoalSheet(context, manager),
                                      ),
                                      WeeklyFitnessTrackWidget(
                                        key: weeklyShareAnchorKey,
                                        primaryValues: state.weeklyPrimaryValues,
                                        goal: stepValue.toInt(),
                                        metrics: state.weeklyMetrics,
                                        offset: state.weeklyOffset,
                                        onClickBackward: () => manager.changeOffset(-1),
                                        onClickForward: () => manager.changeOffset(1),
                                        onClickMoreVert: () => _showActionsSheet(context, manager),
                                        onClickPause: () {},
                                      ),
                                      MonthlyFitnessTrackWidget(
                                        key: monthlyShareAnchorKey,
                                        primaryValues: state.monthlyPrimaryValues,
                                        goal: stepValue.toInt(),
                                        metrics: state.monthlyMetrics,
                                        offset: state.monthlyOffset,
                                        onClickBackward: () => manager.changeOffset(-1),
                                        onClickForward: () => manager.changeOffset(1),
                                        onClickMoreVert: () => _showActionsSheet(context, manager),
                                        onClickPause: () {},
                                      ),
                                    ]
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildTabContent(
                                        screenshotController: _screenshotControllers[entry.key],
                                        fitnessTrackWidget: entry.value,
                                        allUserStatsForPeriod: switch (entry.key) {
                                          0 => state.dailyUserStates,
                                          1 => state.weeklyUserStates,
                                          2 => state.monthlyUserStates,
                                          _ => [],
                                        },
                                        isGettingStats: state.isGettingStats,
                                      ),
                                    )
                                    .toList(),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        .firstWhere((norm) => norm.metric == 'Step', orElse: () => NormsRequest(metric: 'Step', value: 0))
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
              await SharePlus.instance.share(ShareParams(files: [XFile(imagePath.path)], sharePositionOrigin: origin));
            });
          },
        );
      },
    );
  }

  Rect _getWidgetRect(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return Offset.zero & Size.zero;
    final renderBox = context.findRenderObject() as RenderBox?;
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
          LeaderboardSection(allUserStatsForPeriod: allUserStatsForPeriod, isGettingStats: isGettingStats),
        ],
      ),
    );
  }
}
