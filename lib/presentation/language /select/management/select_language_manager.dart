import 'dart:developer';

import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/presentation/language%20/select/management/select_language_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SelectLanguageManager
    extends Manager<SelectLanguageState, SelectLanguageEffect> {
  SelectLanguageManager(this._commonRepo) : super(const SelectLanguageState());

  final CommonRepo _commonRepo;

  void setSelectedLanguage(Language language) {
    log("ResultSelectedLanguage->${language}");
    _commonRepo.setSelectedLanguage(language);
    emit(state.copyWith(selectedLanguage: language));
  }

  void getSelectedLanguage() async {
    await _commonRepo.getSelectedLanguage().handle(
      onStart: () => {log("OnStart")},
      onData: (data) => {
        log("OnEach->$data"),
        emit(state.copyWith(languages: _languages, selectedLanguage: data)),
      },
      onDone: () => {log("OnDone")},
      onError: (error) {
        log("Error->$error");
      },
    );
  }

  List<Language> _languages = [Language.UZ, Language.RU, Language.EN];
}
