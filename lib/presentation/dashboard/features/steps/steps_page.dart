import 'dart:developer';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/health_app_service.dart';
import 'package:calora/common/service/health_data_service.dart';
import 'package:calora/common/service/health_step_service.dart'
    show HealthStepService;
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
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

  // final cmpPedometer = CmpPedometer();

  @override
  void init(context, manager) async {
    // Then later when you need data
    manager.fetchUserStates();
    manager.getSteps();
    manager.getUserMetrics();
    _initializePedometerService();
  }

  void _initializePedometerService() async {
    _pedometerService = PedometerService(
      onPedestrianStatusUpdated: (data) {
        log("StepsPedometerStatus->${data}");
      },
      onStepCountUpdated: (data) {
        log("StepsPedometerLiveCount->${data}");
      },
      onStepCountWeekly: (data) {
        log("StepsPedometerWeeklyCount->${data}");
      },
      onError: (error) {
        log("StepsPedometerError->${error}");
      },
    );
    await _pedometerService.initializePedometer();
    final result = await _pedometerService.getTodaySteps();
    // final past24Hours = await _pedometerService.getStepsPast24Hours();
    // final pastFourHours = await _pedometerService.getWeeklySteps();
    log("StepsPageTodayResult->$result");
  }

  @override
  Widget builder(context, manager, state) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                Assets.icons.background.path,
                fit: BoxFit.fill,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Strings.steps.text(32, 36, 700),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.accentWhite,
                        // Moved color inside decoration
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: TabBar(
                          indicatorPadding: EdgeInsets.all(2),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: context.colors.backgroundElevation,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          labelColor: context.colors.neutral900Primary,
                          unselectedLabelColor:
                              context.colors.neutral600Secondary,
                          tabs: [
                            TabBarItemWidget(name: Strings.daily),
                            TabBarItemWidget(name: Strings.weekly),
                            TabBarItemWidget(name: Strings.monthly),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            FitnessTrackWidget(
                              distance: state.metrics,
                              steps: state.stepCount,
                              onClickBackward: () {},
                              onClickForward: () {},
                              onClickMoreVert: () {
                                _showActionsSheet(context);
                              },
                              onClickPause: () {},
                              onClickEditStepGoal: () {
                                _showEditStepGoalSheet(context);
                              },
                            ),
                            PodiumWidget(
                              firstPosition: state.userStates.isNotEmpty
                                  ? WinnerItemBuilder(
                                      userStat: state.userStates[0],
                                    )
                                  : const SizedBox.shrink(),
                              secondPosition: state.userStates.isNotEmpty
                                  ? WinnerItemBuilder(
                                      userStat: state.userStates[1],
                                    )
                                  : const SizedBox.shrink(),
                              thirdPosition: state.userStates.isNotEmpty
                                  ? WinnerItemBuilder(
                                      userStat: state.userStates[2],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            SizedBox(height: 2),
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
      ),
    );
  }

  void _showEditStepGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditStepGoalPage(initialValue: 16000, onSave: (value) {}),
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
        onTapShare: () {},
        onTapShareApp: () {},
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmPage(onConfirm: () {}, onCancel: () {}),
    );
  }

  @override
  void dispose() {
    _pedometerService.dispose();
    super.dispose();
  }
}
