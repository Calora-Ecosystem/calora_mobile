import 'package:calora/common/enums/connectivity_quality_enum.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'connectivity_management.freezed.dart';

@freezed
abstract class ConnectivityState with _$ConnectivityState {
  const factory ConnectivityState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    @Default(false) bool isError,
    @Default(true) bool isConnected,
    @Default(true) bool hasInterface,
    @Default(ConnectionQuality.excellent) ConnectionQuality connectionQuality,
    @Default([]) List<ConnectivityResult> results,
    required DateTime lastCheckedAt,
  }) = _ConnectivityState;

  factory ConnectivityState.initial() =>
      ConnectivityState(lastCheckedAt: DateTime.now());
}

@freezed
sealed class ConnectivityEffect with _$ConnectivityEffect {
  const factory ConnectivityEffect.showOverlay() = _ShowOverlay;
  const factory ConnectivityEffect.removeOverlay() = _RemoveOverlay;
}
