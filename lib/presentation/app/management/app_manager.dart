import 'package:calora/domain/model/language/language.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/app/management/app_management.dart';

@injectable
class AppManager extends Manager<AppState, AppEffect> {
  AppManager() : super(const AppState());

  void select(Language language) {
    emit(state.copyWith(language: language));
  }
}
