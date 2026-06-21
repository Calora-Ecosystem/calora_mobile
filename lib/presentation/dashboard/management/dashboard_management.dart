import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_management.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(0) int todaySteps,
  }) = _DashboardState;
}

@freezed
class DashboardEffect with _$DashboardEffect {
  const factory DashboardEffect.forceLogout() = _ForceLogout;

  /// Pre-permission rationale dialog.
  /// Shown before we call the system Health Connect/HealthKit permission prompt.
  /// [detectedApp] is one of: 'samsung_health', 'mi_fitness', 'unknown' (Android)
  /// or 'ios' on iOS.
  const factory DashboardEffect.requestHealthPermission({
    required String detectedApp,
  }) = _RequestHealthPermission;

  /// Health permission is granted but the central health repository
  /// keeps reporting ~0 steps because a third-party tracker (Samsung
  /// Health, Mi Fitness, …) hasn't been configured to sync into
  /// Health Connect. [detectedApp] identifies which app to guide the
  /// user toward.
  const factory DashboardEffect.requestHealthSyncFix({
    required String detectedApp,
  }) = _RequestHealthSyncFix;

  /// Android only: ask the user for the "Physical activity" permission
  /// (ACTIVITY_RECOGNITION) that the on-device step sensor needs. Shown as
  /// a non-cancellable priming screen — counting can't start without it.
  const factory DashboardEffect.requestActivityPermission() =
      _RequestActivityPermission;
}
