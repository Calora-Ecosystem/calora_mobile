import 'dart:developer';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/capture_and_share/capture_and_share.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/common/action/actions_page.dart';
import 'package:calora/presentation/common/confirm/confirm_page.dart';
import 'package:calora/presentation/dashboard/features/steps/features/edit/edit_step_goal_page.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/leaderboard/leaderboard_widget.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:calora/widgets/tab/tab_bar_item_widget.dart';
import 'package:calora/widgets/track/fitness_track_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class StepsPage extends Managed<StepsManager, StepsState, StepsEffect> {
  StepsPage({super.key});

  late PedometerService _pedometerService;
  GlobalKey globalKey = GlobalKey();
  int _previousTabIndex = 0;

  @override
  void init(context, manager) {
    manager.getUserMetrics();
    manager.getNorms();
    manager.getSteps();
    manager.getStats(3);
    manager.start();
    _initializePedometerService(manager);
  }

  void _initializePedometerService(StepsManager manager) async {
    _pedometerService = PedometerService(
      onTodayStepCountUpdated: (todaySteps) {
        manager.updateTodaySteps(todaySteps);
      },
      onError: (error) => log('StepsPageError: $error'),
    );
    await _pedometerService.initializePedometer();
  }

  @override
  Widget builder(context, manager, state) {
    final stepValue = state.norms
        .firstWhere((norm) => norm.metric == 'Step', orElse: () => NormsRequest(metric: 'Step', value: 0))
        .value;

    final List<UserStatRequest> userStatesWithPlaceholders = List.generate(
      3,
      (index) => index < state.userStates.length
          ? state.userStates[index]
          : const UserStatRequest(firstName: '-', lastName: '', stepCount: 0, talks: 0),
    );

    return DefaultRefreshIndicator(
      onRefresh: () async {
        manager.getUserMetrics();
        manager.getNorms();
        manager.getSteps();
        manager.getStats(3);
        manager.start();
      },
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
            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: Image.asset(Assets.icons.background.path, fit: BoxFit.fill)),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 0),
                      child: Column(
                        children: [
                          Align(alignment: Alignment.centerLeft, child: Strings.steps.text(32, 36, 700)),
                          const SizedBox(height: 12),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: TabBar(
                              onTap: (index) {
                                if (index != _previousTabIndex) {
                                  _previousTabIndex = index;
                                  manager.changePeriod(index);
                                }
                              },
                              indicatorPadding: const EdgeInsets.all(2),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.grey,
                              tabs: [
                                TabBarItemWidget(name: Strings.daily),
                                TabBarItemWidget(name: Strings.weekly),
                                TabBarItemWidget(name: Strings.monthly),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: const ClampingScrollPhysics()),
                              child: Column(
                                children: [
                                  FitnessTrackWidget(
                                    primaryValues: state.primaryValues,
                                    globalKey: globalKey,
                                    goal: stepValue.toInt(),
                                    metrics: state.metrics,
                                    stepCount: state.displayStepCount,
                                    canGoForward: state.canGoForward,
                                    offset: state.offset,
                                    onClickBackward: () => manager.changeOffset(-1),
                                    onClickForward: () => manager.changeOffset(1),
                                    onClickMoreVert: () => _showActionsSheet(context),
                                    onClickPause: () {},
                                    onClickEditStepGoal: () => _showEditStepGoalSheet(context, manager),
                                  ),
                                  PodiumWidget(
                                    firstPosition: WinnerItemBuilder(
                                      userStat: userStatesWithPlaceholders[0],
                                      loading: state.isGettingStats,
                                    ),
                                    secondPosition: WinnerItemBuilder(
                                      userStat: userStatesWithPlaceholders[1],
                                      loading: state.isGettingStats,
                                    ),
                                    thirdPosition: WinnerItemBuilder(
                                      userStat: userStatesWithPlaceholders[2],
                                      loading: state.isGettingStats,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  LeaderboardWidget(users: state.getUserStates()),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmPage(
        onConfirm: () {},
        onCancel: () {},
        cancelText: Strings.cleaning,
        confirmText: Strings.rejection,
        title: Strings.areYouSureDeleteStatistic,
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
        onSave: (value) {
          manager.updateNorm(NormsRequest(metric: 'Step', value: value.toDouble()));
        },
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ActionsPage(
        onTapDelete: () => _showConfirmDialog(context),
        onTapShare: () => captureAndShare(globalKey),
      ),
    );
  }

  @override
  void dispose() {
    _pedometerService.dispose();
    super.dispose();
  }
}
