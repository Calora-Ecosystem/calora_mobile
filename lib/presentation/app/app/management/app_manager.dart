import 'package:calora/domain/model/language/language.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AppManager extends Manager<AppState, AppEffect> {
  AppManager() : super(const AppState());

  void select(Language language) {
    emit(state.copyWith(language: language));
  }
}
