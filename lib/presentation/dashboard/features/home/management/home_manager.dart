import 'dart:async';
import 'dart:io';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/domain/model/summary/summary_request.dart';
import 'package:calora/domain/repo/home/home_repo.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {
  final ProfileRepo _profileRepo;
  final StepRepo _stepRepo;
  final HomeRepo _homeRepo;
  final NotificationRepo _notificationRepo;
  final MetricsSyncService _metricsSync;
  final Health _health = Health();

  HomeManager(
    this._profileRepo,
    this._stepRepo,
    this._homeRepo,
    this._notificationRepo,
    this._metricsSync,
  ) : super(HomeState());

  StreamSubscription<int>? _metricsSyncSub;
  Timer? _metricsDebounce;
  bool _metricsInFlight = false;

  bool _fgsStarted = false;
  Future<void>? _fgsInitFuture;

  static Future<Map<Permission, PermissionStatus>>? _globalPermFuture;
  static final _permLock = Object();

  Future<void> initStepsForeground() {
    _fgsInitFuture ??= _initStepsForegroundInternal();
    return _fgsInitFuture!;
  }

  static Future<Map<Permission, PermissionStatus>> _requestPermissionsOnce({
    required bool includeNotifications,
  }) {
    if (_globalPermFuture != null) {
      return _globalPermFuture!;
    }

    synchronized(_permLock, () {
      if (_globalPermFuture != null) return _globalPermFuture!;

      final perms = <Permission>[
        if (Platform.isAndroid) Permission.activityRecognition,
        if (Platform.isIOS) Permission.sensors,
        if (includeNotifications) Permission.notification,
      ];

      _globalPermFuture = perms
          .request()
          .then((result) => result)
          .catchError((e, s) => <Permission, PermissionStatus>{})
          .whenComplete(() {
            Future.delayed(const Duration(milliseconds: 500), () {
              _globalPermFuture = null;
            });
          });

      return _globalPermFuture!;
    });

    return _globalPermFuture!;
  }

  static Future<T> synchronized<T>(Object lock, Future<T> Function() fn) async {
    return await fn();
  }

  Future<void> _initStepsForegroundInternal() async {
    if (_fgsStarted) return;

    try {
      final statuses = await _requestPermissionsOnce(includeNotifications: true);

      final bool arOk;
      if (Platform.isAndroid) {
        arOk = statuses[Permission.activityRecognition]?.isGranted == true;
      } else if (Platform.isIOS) {
        arOk = statuses[Permission.sensors]?.isGranted == true;
      } else {
        arOk = false;
      }

      if (!arOk) return;

      await _requestHealthPermissions();

      final goalSteps = state.targetSteps > 0 ? state.targetSteps : 10000;
      StepsForegroundService.instance.setGoalSteps(goalSteps);

      final ok = await StepsForegroundService.instance.start();
      _fgsStarted = ok;
    } catch (e) {
      _fgsStarted = false;
    }
  }

  Future<void> _requestHealthPermissions() async {
    try {
      await _health.configure();

      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailable ||
            status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          return;
        }
      }

      final types = [HealthDataType.STEPS];
      final bool? hasPermissions = await _health.hasPermissions(
        types,
        permissions: [HealthDataAccess.READ],
      );

      if (hasPermissions != true) {
        await _health.requestAuthorization(
          types,
          permissions: [HealthDataAccess.READ],
        );
      }
    } catch (e) {}
  }

  Future<void> requestPedometerPermissions() async {
    await _requestPermissionsOnce(includeNotifications: false);
  }

  Future<void> getUserInfo() async => await _profileRepo.getProfile().handle(
    onStart: () => emit(state.copyWith(isLoading: true)),
    onError: (_) => emit(state.copyWith(isLoading: false)),
    onData: (profile) {
      emit(state.copyWith(profile: profile, isLoading: false));
      profileStore.clear();
      profileStore.set(profile);
      final w = (profile.weight ?? 0).toDouble();
      if (w > 0) StepsForegroundService.instance.setUserWeight(w);
    },
  );

  void updateDay(DateTime day) {
    emit(state.copyWith(day: day));

    if (_isToday(day)) {
      _startMetricsLiveSync();
      getMetrics(showLoading: false);
    } else {
      _stopMetricsLiveSync();
      getDailyStep();
      getMetrics();
    }
  }

  void _startMetricsLiveSync() {
    _metricsSyncSub?.cancel();

    _metricsSyncSub = _metricsSync.stream.listen((steps) {
      _scheduleMetricsRefresh();
    });

    _scheduleMetricsRefresh(immediate: true);
  }

  void _stopMetricsLiveSync() {
    _metricsDebounce?.cancel();
    _metricsDebounce = null;

    _metricsSyncSub?.cancel();
    _metricsSyncSub = null;
  }

  void _scheduleMetricsRefresh({bool immediate = false}) {
    if (!_isToday(state.day ?? DateTime.now())) return;

    _metricsDebounce?.cancel();

    if (immediate) {
      getMetrics(showLoading: false);
      return;
    }

    _metricsDebounce = Timer(const Duration(milliseconds: 800), () {
      getMetrics(showLoading: false);
    });
  }

  void updateWaterIntake(double liters) {
    emit(state.copyWith(waterIntake: liters));
  }

  void postWater() {
    _homeRepo.postWater(
      DailiesRequest(
        metric: 'Water',
        value: state.waterIntake,
        date: DateTime.now().toIso8601String(),
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return now.year == day.year && now.month == day.month && now.day == day.day;
  }

  void getDailyStep() {
    final day = state.day ?? DateTime.now();
    _homeRepo
        .getDailiesSteps(day)
        .handle(
          onStart: () => emit(state.copyWith(isMetricsLoading: true)),
          onData: (data) => emit(
            state.copyWith(
              currentSteps: data.value.toInt(),
              isMetricsLoading: false,
            ),
          ),
          onError: (_) => emit(state.copyWith(isMetricsLoading: false)),
        );
  }

  void getWater() {
    _homeRepo
        .getDailiesWater(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isWaterLoading: true)),
          onData: (data) => emit(
            state.copyWith(
              waterIntake: data.value,
              isWaterLoading: false,
            ),
          ),
          onError: (_) => emit(state.copyWith(isWaterLoading: false)),
        );
  }

  void getSummary() {
    _homeRepo
        .getSummary(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isSummaryLoading: true)),
          onData: (data) {
            emit(state.copyWith(summary: data, isSummaryLoading: false));
            updateNutrientsPercent(data);
          },
          onError: (_) => emit(state.copyWith(isSummaryLoading: false)),
        );
  }

  void getMetrics({bool showLoading = true}) {
    if (_metricsInFlight) return;
    _metricsInFlight = true;

    final day = state.day ?? DateTime.now();
    final isToday = _isToday(day);

    _homeRepo
        .getMetrics(day)
        .handle(
          onStart: () {
            if (showLoading && !isToday) {
              emit(state.copyWith(isMetricsLoading: true));
            }
          },
          onData: (data) {
            emit(state.copyWith(metrics: data, isMetricsLoading: false));
          },
          onError: (_) => emit(state.copyWith(isMetricsLoading: false)),
          onDone: () => _metricsInFlight = false,
        );
  }

  void getStepNorm() {
    _stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) async {
        final stepValue = data
            .firstWhere(
              (e) => e.metric == 'Step',
              orElse: () => NormsRequest(metric: 'Step', value: 0),
            )
            .value;

        final waterValue = data
            .firstWhere(
              (e) => e.metric == 'Water',
              orElse: () => NormsRequest(metric: 'Water', value: 0),
            )
            .value;

        final kcalValue = data
            .firstWhere(
              (e) => e.metric == 'Kcal',
              orElse: () => NormsRequest(metric: 'Kcal', value: 0),
            )
            .value;

        final newTargetSteps = stepValue.toInt();

        emit(
          state.copyWith(
            norms: data,
            isLoading: false,
            targetSteps: newTargetSteps,
            targetLiters: waterValue,
            targetKcal: kcalValue,
          ),
        );

        if (newTargetSteps > 0) {
          StepsForegroundService.instance.setGoalSteps(newTargetSteps);
          if (_fgsStarted) {
            unawaited(StepsForegroundService.instance.updateGoal(newTargetSteps));
          }
        }
      },
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  void updateNutrientsPercent(SummaryRequest summary) {
    final proteinNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Protein',
          orElse: () => NormsRequest(metric: 'Protein', value: 1),
        )
        .value;

    final fatNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Fat',
          orElse: () => NormsRequest(metric: 'Fat', value: 1),
        )
        .value;

    final carbNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Carb',
          orElse: () => NormsRequest(metric: 'Carb', value: 1),
        )
        .value;

    emit(
      state.copyWith(
        nutrients: [
          NutrientInfo(
            name: Strings.proteins,
            value: summary.sum.Protein,
            percent: proteinNorm > 0 ? (summary.sum.Protein / proteinNorm).clamp(0.0, 1.0) : 0,
          ),
          NutrientInfo(
            name: Strings.oils,
            value: summary.sum.Fat,
            percent: fatNorm > 0 ? (summary.sum.Fat / fatNorm).clamp(0.0, 1.0) : 0,
          ),
          NutrientInfo(
            name: Strings.carbohydrates,
            value: summary.sum.Carb,
            percent: carbNorm > 0 ? (summary.sum.Carb / carbNorm).clamp(0.0, 1.0) : 0,
          ),
        ],
      ),
    );
  }

  void getUnreadCount() {
    _notificationRepo.getUnread().listen((unreadCount) {
      emit(state.copyWith(unreadCount: unreadCount));
    });
  }

  @override
  Future<void> close() async {
    _stopMetricsLiveSync();
    await super.close();
  }
}

extension HomeManagerX on HomeManager {
  Future<void> refreshAll() async {
    final mustUpdate = await _shouldForceUpdate();
    if (mustUpdate) {
      publish(const HomeEffect.forceUpdate());
      return;
    }
    getUserInfo();
    getStepNorm();
    getSummary();
    getWater();
    getUnreadCount();

    final day = state.day ?? DateTime.now();
    if (_isToday(day)) {
      _startMetricsLiveSync();
    } else {
      _stopMetricsLiveSync();
      getDailyStep();
    }
    getMetrics();
  }

  Future<bool> _shouldForceUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version.split('+').first.trim();

      final active = await _homeRepo.isVersionActive(currentVersion);
      return !active;
    } catch (e) {
      return false;
    }
  }
}
