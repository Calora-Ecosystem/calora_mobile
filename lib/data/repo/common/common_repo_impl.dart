import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CommonRepo)
class CommonRepoImpl extends CommonRepo {
  final CommonStore _commonStore;
  final AuthStore _store;

  CommonRepoImpl(this._commonStore, this._store);

  @override
  Future<void> setSelectedLanguage(Language language) {
    return _commonStore.language.set(language);
  }

  @override
  Future<Language> getSelectedLanguage() async {
    final result = await _commonStore.language.call();
    return result ?? Language.UZ;
  }

  @override
  Future<void> setLanguageSelectedFlag(bool value) async {
    return _commonStore.isLanguageSelected.set(value);
  }

  @override
  Future<void> setOnboardingCompletedFlag(bool value) {
    return _commonStore.isOnboardingCompleted.set(value);
  }
}
