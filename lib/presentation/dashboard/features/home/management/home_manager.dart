import 'dart:async';
import 'dart:developer';

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
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {
  final ProfileRepo _profileRepo;
  final StepRepo _stepRepo;
  final HomeRepo _homeRepo;
  final NotificationRepo _notificationRepo;
  final MetricsSyncService _metricsSync;

  HomeManager(
    this._profileRepo,
    this._stepRepo,
    this._homeRepo,
    this._notificationRepo,
    this._metricsSync,
  ) : super(HomeState());

  // ===== Metrics live sync =====
  StreamSubscription<int>? _metricsSyncSub;
  Timer? _metricsDebounce;
  bool _metricsInFlight = false;

  // ===== Foreground service =====
  bool _fgsStarted = false;
  Future<void>? _fgsInitFuture;

  // ===== Permission single-flight (FIX) =====
  Future<Map<Permission, PermissionStatus>>? _permFuture;

  // ===== Fake notif (debug) =====
  Timer? _fakeDataTimer;
  int _fakeSteps = 0;

  /// Public API: safe init (won't run twice).
  Future<void> initStepsForeground() {
    // Agar allaqachon init ketayotgan bo‘lsa — o‘sha future qaytadi.
    _fgsInitFuture ??= _initStepsForegroundInternal().whenComplete(() {
      // init tugagach, _fgsInitFuture ni null qilmaymiz — chunki qayta-qayta
      // init qilish shart emas. Faqat stop bo‘lsa qayta init bo‘ladi.
    });

    return _fgsInitFuture!;
  }

  /// Single-flight permission request.
  /// Bir paytda bir nechta .request() bo‘lib ketmasin — asosiy fix shu.
  Future<Map<Permission, PermissionStatus>> _requestPermissionsOnce({
    required bool includeNotifications,
  }) {
    if (_permFuture != null) return _permFuture!;

    final perms = <Permission>[
      Permission.activityRecognition,
      Permission.sensors,
      Permission.locationWhenInUse,
      if (includeNotifications) Permission.notification, // Android 13+
    ];

    _permFuture = perms.request().whenComplete(() {
      // User settingsni o‘zgartirib qaytib kelsa, keyingi safar qayta so‘rashi mumkin.
      _permFuture = null;
    });

    return _permFuture!;
  }

  Future<void> _initStepsForegroundInternal() async {
    if (_fgsStarted) return;

    final statuses = await _requestPermissionsOnce(includeNotifications: true);

    final arOk = statuses[Permission.activityRecognition]?.isGranted == true;
    final notifOk = statuses[Permission.notification]?.isGranted == true;

    if (!arOk || !notifOk) {
      log('Native FGS permissions not granted: $statuses', name: 'HomeManager');
      return;
    }

    final goalSteps = state.targetSteps > 0 ? state.targetSteps : 10000;
    StepsForegroundService.instance.setGoalSteps(goalSteps);

    final ok = await StepsForegroundService.instance.start(
      initialSteps: state.currentSteps,
    );

    _fgsStarted = ok;
    log('Native FGS started=$_fgsStarted goal=$goalSteps', name: 'HomeManager');
  }

  // Optional: agar siz faqat permission so‘rashni alohida chaqirsangiz ham conflict bo‘lmaydi.
  Future<void> requestPedometerPermissions() async {
    await _requestPermissionsOnce(includeNotifications: false);
  }

  // Debug helper
  Future<void> startFakeNativeNotif() async {
    await initStepsForeground();
    if (!_fgsStarted) return;

    _fakeDataTimer?.cancel();
    _fakeSteps = 0;

    _fakeDataTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _fakeSteps += 37;
      updateTodaySteps(_fakeSteps);

      try {
        await StepsForegroundService.instance.updateSteps(_fakeSteps);
      } catch (e, s) {
        log('updateSteps error: $e', name: 'HomeManager', stackTrace: s);
      }
    });

    log('Fake native notification started', name: 'HomeManager');
  }

  Future<void> stopFakeNativeNotif() async {
    _fakeDataTimer?.cancel();
    _fakeDataTimer = null;

    try {
      await StepsForegroundService.instance.stop();
    } catch (e, s) {
      log('stop FGS error: $e', name: 'HomeManager', stackTrace: s);
    }

    _fgsStarted = false;
    // Stop bo‘lgach qayta init kerak bo‘lishi mumkin:
    _fgsInitFuture = null;

    log('Fake native notification stopped', name: 'HomeManager');
  }

  // ===== Profile / daily flow =====

  Future<void> getUserInfo() async => await _profileRepo.getProfile().handle(
    onStart: () => emit(state.copyWith(isLoading: true)),
    onError: (_) => emit(state.copyWith(isLoading: false)),
    onData: (profile) {
      emit(state.copyWith(profile: profile, isLoading: false));
      profileStore.clear();
      profileStore.set(profile);
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
      log('📣 HomeManager received sync notification: steps=$steps', name: 'HomeManager');
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

  void updateTodaySteps(int steps) {
    final day = state.day ?? DateTime.now();
    if (!_isToday(day)) return;

    emit(state.copyWith(currentSteps: steps));

    if (_fgsStarted) {
      // fire-and-forget; exception bo‘lsa crash qilmasin
      unawaited(_safeUpdateFgsSteps(steps));
    }
  }

  Future<void> _safeUpdateFgsSteps(int steps) async {
    try {
      await StepsForegroundService.instance.updateSteps(steps);
    } catch (e, s) {
      log('FGS updateSteps error: $e', name: 'HomeManager', stackTrace: s);
    }
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
      onData: (data) {
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

        emit(
          state.copyWith(
            norms: data,
            isLoading: false,
            targetSteps: stepValue.toInt(),
            targetLiters: waterValue,
            targetKcal: kcalValue,
          ),
        );
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

  // ===== Lifecycle =====

  @override
  Future<void> close() async {
    _stopMetricsLiveSync();

    _fakeDataTimer?.cancel();
    _fakeDataTimer = null;

    if (_fgsStarted) {
      try {
        await StepsForegroundService.instance.stop();
      } catch (e, s) {
        log('close stop FGS error: $e', name: 'HomeManager', stackTrace: s);
      }
      _fgsStarted = false;
      _fgsInitFuture = null;
    }

    await super.close();
  }
}

extension HomeManagerX on HomeManager {
  Future<void> refreshAll() async {
    getUserInfo();
    getStepNorm();
    getSummary();
    getWater();
    getUnreadCount();

    final day = state.day ?? DateTime.now();
    if (_isToday(day)) {
      _startMetricsLiveSync();
      getMetrics(showLoading: false);
    } else {
      _stopMetricsLiveSync();
      getDailyStep();
      getMetrics();
    }
  }
}
