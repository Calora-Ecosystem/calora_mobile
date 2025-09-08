import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/pedometr_service.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:calora/widgets/tab/tab_bar_item_widget.dart';
import 'package:calora/widgets/track%20/fitness_track_widget.dart';
import 'package:flutter/material.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:management/management.dart';

@RoutePage()
class StepsPage extends Managed<StepsManager, StepsState, StepsEffect> {
  StepsPage({super.key});

  late PedometerService _pedometerService;

  @override
  void init(context, manager) {
    _initializePedometerService();
  }

  void _initializePedometerService() async {
    _pedometerService = PedometerService(
      onStepCountUpdate: (count) {
        log("SteCount->${count}");
      },
      onStatusUpdate: (status) {
        log("SteStatus->${status}");
      },
      onPermissionUpdate: (granted) {
        log("StePermission->${granted}");
      },
      onError: (error) {
        log("SteError->${error}");
      },
    );
    await _pedometerService.initialize();
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(Assets.icons.background.path, fit: BoxFit.fill),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                    child: DefaultTabController(
                      length: 3,
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
                  ),
                  SizedBox(height: 16),
                  FitnessTrackWidget(
                    onClickBackward: () {},
                    onClickForward: () {},
                    onClickMoreVert: () {},
                    onClickPause: () {},
                  ),
                  Center(
                    child: PodiumWidget(
                      firstPosition: Text("Winner 1"),
                      secondPosition: Text("Winner 2"),
                      thirdPosition: Text("Winner 3"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pedometerService.dispose();
    super.dispose();
  }
}
