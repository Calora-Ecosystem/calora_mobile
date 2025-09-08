import 'package:calora/domain/model/language/language.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_language_management.freezed.dart';

@freezed
abstract class SelectLanguageState with _$SelectLanguageState {
  const factory SelectLanguageState({
    @Default([Language.UZ]) List<Language> languages,
    @Default(Language.UZ) Language selectedLanguage,
  }) = _SelectLanguageState;
}

@freezed
sealed class SelectLanguageEffect with _$SelectLanguageEffect {
  const factory SelectLanguageEffect() = _SelectLanguageEffect;
}
