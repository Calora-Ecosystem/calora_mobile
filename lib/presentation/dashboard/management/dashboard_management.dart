import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_management.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState() = _DashboardState;
}

@freezed
class DashboardEffect with _$DashboardEffect {
  const factory DashboardEffect() = _DashboardEffect;
}