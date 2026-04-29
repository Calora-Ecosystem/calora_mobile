import 'dart:developer';
import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthAppService {
  final health = Health();

  List<HealthDataPoint> _healthDataList = [];

  List<RecordingMethod> recordingMethodsToFilter = [];

  static final types = [HealthDataType.STEPS];

  Future<void> initHealthConfig() async {
    await health.configure();
    await health.getHealthConnectSdkStatus();
  }

  Future<void> installHealthConnect() async => await health.installHealthConnect();

  Future<void> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, 'This is only available on Android');

    final status = await health.getHealthConnectSdkStatus();
    log('HealthAppService - Status $status');
  }

  Future<void> authorize() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    final permissions = [HealthDataAccess.READ, HealthDataAccess.WRITE];
    bool? hasPermissions = false;
    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      try {
        authorized = await health.requestAuthorization(
          types,
          permissions: permissions,
        );

        await health.requestHealthDataHistoryAuthorization();

        await health.requestHealthDataInBackgroundAuthorization();
      } catch (error) {
        log('HealthAppService - Exception in authorize: $error');
      }
    }
    log('HealthAppServiceAuthorized->$authorized');
  }

  Future<void> fetchStepData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final permissions = [HealthDataAccess.READ, HealthDataAccess.WRITE];
    bool? hasPermissions = await health.hasPermissions([HealthDataType.STEPS]);
    log('HealthAppService - Initial permission check: $hasPermissions');

    if (hasPermissions != true) {
      log('HealthAppService - Requesting steps authorization...');
      final bool authorized = await health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      log('HealthAppService - Authorization result: $authorized');

      hasPermissions = await health.hasPermissions([HealthDataType.STEPS]);
      log('HealthAppService - Permission check after request: $hasPermissions');
    }

    if (hasPermissions == true) {
      try {
        final int? steps = await health.getTotalStepsInInterval(midnight, now);
        log('HealthAppService - Total steps: $steps');
      } catch (error) {
        log('HealthAppService - Exception: $error');
      }
    } else {
      log('HealthAppService - Final authorization check failed');
    }
  }
}
