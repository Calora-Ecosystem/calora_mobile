import 'dart:async';

import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AppManager extends Manager<AppState, AppEffect> {
  final CommonStore _commonStore;
  StreamSubscription<bool>? _premiumSub;
  AppManager(this._commonStore) : super(const AppState()) {
    _init();
  }

  Future<void> _init() async {
    final isPremium = await _commonStore.isUserPremium();
    emit(state.copyWith(isUserPremium: isPremium));
    _premiumSub = _commonStore.isUserPremium.watch().listen((value) {
      emit(state.copyWith(isUserPremium: value));
    });
  }

  void select(Language language) {
    emit(state.copyWith(language: language));
  }

  @override
  Future<void> close() {
    _premiumSub?.cancel();
    return super.close();
  }
}
