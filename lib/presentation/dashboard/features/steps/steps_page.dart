import 'dart:async';
import 'dart:developer';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/capture_and_share/capture_and_share.dart';
import 'package:calora/domain/model/norms/norms.dart';
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
  int _offset = 0;

  @override
  void init(context, manager) {
    manager.getUserMetrics();
    manager.getNorms();
    manager.getSteps(0, offset: _offset);
    manager.getStats(0, offset: _offset);
    _initializePedometerService(manager);
    Timer.periodic(const Duration(hours: 1), (_) {
      manager.sendDailyData(metric: "Step", value: manager.state.stepCount);
    });
  }

  void _initializePedometerService(StepsManager manager) async {
    _pedometerService = PedometerService(
      onTodayStepCountUpdated: (todaySteps) {
        manager.updateTodaySteps(todaySteps);
      },
      onError: (error) {
        print('StepsPageError: $error');
      },
    );
    await _pedometerService.initializePedometer();
  }

  GlobalKey globalKey = GlobalKey();

  void _changeOffset(int change, int period, StepsManager manager) {
    _offset += change;
    manager.getSteps(period, offset: _offset);
    manager.getStats(period, offset: _offset);
  }

  @override
  Widget builder(context, manager, state) {
    final stepValue = state.norms
        .firstWhere((norm) => norm.metric == "Step", orElse: () => Norms(metric: "Step", value: 0))
        .value;
    log('StepCount::::::::::::::::::::::::::::${state.stepCount}');

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              _offset = 0;
              final period = tabController.index;
              manager.getSteps(period, offset: _offset);
              manager.getStats(period, offset: _offset);
            }
          });

          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: Image.asset(Assets.icons.background.path, fit: BoxFit.fill)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Strings.steps.text(32, 36, 700),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            indicatorPadding: EdgeInsets.all(2),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                FitnessTrackWidget(
                                  primaryValues: state.steps.map((e) => e.value).toList(),
                                  globalKey: globalKey,
                                  goal: stepValue,
                                  metrics: state.metrics,
                                  stepCount: state.stepCount,
                                  onClickBackward: () {
                                    _changeOffset(-1, tabController.index, manager);
                                  },
                                  onClickForward: () {
                                    _changeOffset(1, tabController.index, manager);
                                  },
                                  onClickMoreVert: () {
                                    _showActionsSheet(context);
                                  },
                                  onClickPause: () {},
                                  onClickEditStepGoal: () {
                                    _showEditStepGoalSheet(context, manager);
                                  },
                                ),
                                state.isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : PodiumWidget(
                                        firstPosition: state.userStates.isNotEmpty
                                            ? WinnerItemBuilder(userStat: state.userStates[0])
                                            : const SizedBox.shrink(),
                                        secondPosition: state.userStates.length > 1
                                            ? WinnerItemBuilder(userStat: state.userStates[1])
                                            : const SizedBox.shrink(),
                                        thirdPosition: state.userStates.length > 2
                                            ? WinnerItemBuilder(userStat: state.userStates[2])
                                            : const SizedBox.shrink(),
                                      ),
                                const SizedBox(height: 2),
                                LeaderboardWidget(users: state.getUserStates()),
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
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmPage(onConfirm: () {}, onCancel: () {}),
    );
  }

  void _showEditStepGoalSheet(BuildContext context, StepsManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditStepGoalPage(
        initialValue: 16000,
        onSave: (value) {
          manager.update(Norms(metric: "Step", value: value));
          manager.getNorms();
        },
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ActionsPage(
        onTapDelete: () {
          _showConfirmDialog(context);
        },
        onTapShare: () {
          captureAndShare(globalKey);
        },
        onTapShareApp: () {},
      ),
    );
  }

  @override
  void dispose() {
    _pedometerService.dispose();
    super.dispose();
  }
}
