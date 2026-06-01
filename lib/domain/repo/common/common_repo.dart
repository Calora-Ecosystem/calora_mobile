import 'package:calora/domain/model/language/language.dart';

abstract class CommonRepo {
  /// Persists the selected language and resolves only after the underlying
  /// SharedPreferences write completes. Callers that immediately fire a
  /// network request rely on this — the TokenInterceptor reads the same
  /// store to set `Accept-Language`, so racing the write would send the
  /// previous language code on the next request.
  Future<void> setSelectedLanguage(Language language);

  Future<Language> getSelectedLanguage();

  Future<void> setLanguageSelectedFlag(bool value);

  Future<void> setOnboardingCompletedFlag(bool value);
}
