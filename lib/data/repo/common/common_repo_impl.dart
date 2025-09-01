import 'dart:developer';

import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CommonRepo)
class CommonRepoImpl extends CommonRepo {
  final CommonStore _commonStore;

  CommonRepoImpl(this._commonStore);

  @override
  void setSelectedLanguage(Language language) {
    _commonStore.language.set(language);
  }

  @override
  Future<Language> getSelectedLanguage() async {
    final result = await _commonStore.language.call();
    return result ?? Language.UZ;
  }
}
