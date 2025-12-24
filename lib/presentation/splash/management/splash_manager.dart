import 'dart:developer';

import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/presentation/splash/management/splash_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SplashManager extends Manager<SplashState, SplashEffect> {
  final AuthStore _authStore;
  final CommonStore _commonStore;

  SplashManager(this._authStore, this._commonStore) : super(const SplashState()) {
    checkAuth();
  }

  void checkAuth() async {
    final results = await Future.wait([
      _authStore.token(),
      _commonStore.isLanguageSelected(),
      _commonStore.isOnboardingCompleted(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    final Token? token = results[0] as Token?;
    final bool isLanguageSelected = results[1] as bool;
    final bool isOnboardingCompleted = results[2] as bool;
    log("refresh token:======${token}");
    if (token != null && token.accessToken != null) {
      publish(const SplashEffect.dashboard());
    } else {
      if (!isLanguageSelected) {
        publish(const SplashEffect.language());
      } else if (!isOnboardingCompleted) {
        publish(const SplashEffect.onboarding());
      } else {
        publish(const SplashEffect.auth());
      }
    }
  }
}
