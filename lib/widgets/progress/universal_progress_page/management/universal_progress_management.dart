import 'package:freezed_annotation/freezed_annotation.dart';

part 'universal_progress_management.freezed.dart';

@freezed
abstract class UniversalProgressState with _$UniversalProgressState {
  const factory UniversalProgressState({@Default(0.0) double progress, @Default(false) bool isCompleted}) =
      _UniversalProgressState;
}

@freezed
sealed class UniversalProgressEffect with _$UniversalProgressEffect {
  const factory UniversalProgressEffect.completed() = UniversalProgressEffectCompleted;
}
