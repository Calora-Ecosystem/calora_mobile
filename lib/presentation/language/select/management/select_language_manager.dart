import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/presentation/language/select/management/select_language_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SelectLanguageManager extends Manager<SelectLanguageState, SelectLanguageEffect> {
  SelectLanguageManager(this._commonRepo) : super(const SelectLanguageState());

  final CommonRepo _commonRepo;

  void setSelectedLanguage(Language language) {
    _commonRepo.setSelectedLanguage(language);
    emit(state.copyWith(selectedLanguage: language));
  }

  void getSelectedLanguage() async {
    await _commonRepo.getSelectedLanguage().handle(
      onStart: () => {},
      onData: (data) => {emit(state.copyWith(languages: _languages, selectedLanguage: data))},
      onDone: () => {},
      onError: (error) {},
    );
  }

  List<Language> _languages = [Language.UZ, Language.RU, Language.EN];

  void setLanguageSelectedFlag() => _commonRepo.setLanguageSelectedFlag(true);
}
