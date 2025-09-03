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
  void setSelectedLanguage(Language language) {
    _commonStore.language.set(language);
  }

  @override
  Future<Language> getSelectedLanguage() async {
    final result = await _commonStore.language.call();
    return result ?? Language.UZ;
  }

  @override
  Future<bool> isLogin() {
    return _store.isLogin.call().then((value) => value ?? false);
  }
}
