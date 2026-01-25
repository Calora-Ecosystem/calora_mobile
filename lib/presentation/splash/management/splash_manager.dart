import 'package:calora/common/base/profile_store.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/domain/repo/splash/splash_repo.dart';
import 'package:calora/presentation/splash/management/splash_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SplashManager extends Manager<SplashState, SplashEffect> {
  final AuthStore _authStore;
  final CommonStore _commonStore;
  final ProfileStore _profileStore;
  final SplashRepo _splashRepo;
  SplashManager(
    this._authStore,
    this._commonStore,
    this._profileStore,
    this._splashRepo,
  ) : super(const SplashState()) {
    checkAuth();
  }

  void checkAuth() async {
    final results = await Future.wait([
      _authStore.token(),
      _commonStore.isLanguageSelected(),
      _commonStore.isOnboardingCompleted(),
      _commonStore.isQuestionaryFinished(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    Token? token = results[0] as Token?;
    final bool isLanguageSelected = results[1] as bool;
    final bool isOnboardingCompleted = results[2] as bool;
    final bool isQuestionaryFinished = results[3] as bool;

    if (token?.refreshTokenExpireAt != null &&
        token!.refreshTokenExpireAt!.isBefore(DateTime.now())) {
      await _authStore.token.clear();
      await _profileStore.clear();
      token = null;
    }

    if (token != null && token.accessToken != null) {
      if (isQuestionaryFinished) {
        publish(const SplashEffect.dashboard());
      } else {
        publish(const SplashEffect.questionary());
      }
    } else {
      final isUzbekistan = await getCurrentCountry();
      if (!isLanguageSelected) {
        publish(const SplashEffect.language());
      } else if (!isOnboardingCompleted) {
        publish(const SplashEffect.onboarding());
      } else {
        publish(SplashEffect.auth(isUzbekistan));
      }
    }
  }

  Future<bool> getCurrentCountry() async =>
      await _splashRepo.getCurrentCountry();
}
