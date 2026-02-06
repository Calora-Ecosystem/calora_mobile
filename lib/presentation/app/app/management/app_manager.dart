import 'dart:async';
import 'dart:developer';

import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';

import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AppManager extends Manager<AppState, AppEffect> {
  final CommonStore _commonStore;
  final StepRepo _stepRepo;
  final TokenInterceptor _tokenInterceptor;
  final AuthStore _authStore;

  StreamSubscription<bool>? _premiumSub;

  AppManager(
    this._commonStore,
    this._stepRepo,
    this._tokenInterceptor,
    this._authStore,
  ) : super(const AppState()) {
    _init();
  }

  Future<void> _init() async {
    final isPremium = await _commonStore.isUserPremium();
    emit(state.copyWith(isUserPremium: isPremium));
    _premiumSub = _commonStore.isUserPremium.watch().listen((value) {
      emit(state.copyWith(isUserPremium: value));
    });
  }

  Future<void> _handleReLoginRequired() async {
    await _authStore.token.set(null);
    await _commonStore.isQuestionaryFinished.set(false);
    publish(const AppEffect.reLoginRequired());
  }

  void select(Language language) => emit(state.copyWith(language: language));

  @override
  Future<void> close() {
    _premiumSub?.cancel();
    return super.close();
  }
}
