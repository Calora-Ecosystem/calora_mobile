import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_management.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({ProfileRequest? profile, @Default(false) bool isLoading}) = _HomeState;
}

@freezed
class HomeEffect with _$HomeEffect {
  const factory HomeEffect() = _HomeEffect;
}
