import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/service/pedometr_service.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettings;
import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:flutter/material.dart';
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
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(child: Text("Coming soon")),
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
