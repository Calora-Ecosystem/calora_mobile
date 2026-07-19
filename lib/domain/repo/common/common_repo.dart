import 'package:calora/common/util/cached.dart';
import 'package:calora/domain/model/language/language.dart';

abstract class CommonRepo {
  Cached<bool> getIsUzbekistan();

  Future<void> setSelectedLanguage(Language language);

  Future<Language> getSelectedLanguage();

  Future<void> setLanguageSelectedFlag(bool value);

  Future<void> setOnboardingCompletedFlag(bool value);
}
