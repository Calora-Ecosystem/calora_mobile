import 'package:freezed_annotation/freezed_annotation.dart';

part 'calories_management.freezed.dart';

@freezed
abstract class CaloriesState with _$CaloriesState {
  const factory CaloriesState() = _CaloriesState;
}

@freezed
class CaloriesEffect with _$CaloriesEffect {
  const factory CaloriesEffect() = _CaloriesEffect;
}
