import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_management.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState() = _HomeState;
}

@freezed
class HomeEffect with _$HomeEffect {
  const factory HomeEffect() = _HomeEffect;
}
