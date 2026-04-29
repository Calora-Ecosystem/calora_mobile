import 'package:calora/domain/model/language/language.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_management.freezed.dart';

@freezed
abstract class AppState with _$AppState {
  const factory AppState({
    Language? language,
    @Default(false) bool isUserPremium,
  }) = _AppState;
}

@freezed
class AppEffect with _$AppEffect {
  const factory AppEffect() = _AppEffect;
  const factory AppEffect.reLoginRequired() = _ReLoginRequired;
}
