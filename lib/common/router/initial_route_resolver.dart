import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:injectable/injectable.dart';

@injectable
class InitialRouteResolver {
  InitialRouteResolver(this._authStore, this._commonStore, this._profileStore);

  final AuthStore _authStore;
  final CommonStore _commonStore;
  final ProfileStore _profileStore;

  Future<PageRouteInfo> resolve() async {
    final (
      token,
      isLanguageSelected,
      isOnboardingCompleted,
      isQuestionaryFinished,
    ) = await (
      _activeToken(),
      _commonStore.isLanguageSelected(),
      _commonStore.isOnboardingCompleted(),
      _commonStore.isQuestionaryFinished(),
    ).wait;

    if (token?.accessToken != null) {
      return isQuestionaryFinished ? DashboardRoute() : QuestionsRoute();
    }
    if (!isLanguageSelected) return const SelectLanguageRoute();
    if (!isOnboardingCompleted) return const OnboardingRoute();
    return AuthRoute();
  }

  Future<Token?> _activeToken() async {
    final token = await _authStore.token();
    final refreshExpiry = token?.refreshTokenExpireAt;
    if (refreshExpiry == null || !refreshExpiry.isBefore(DateTime.now())) {
      return token;
    }
    await _authStore.token.clear();
    await _profileStore.clear();
    await FacebookAnalyticsService.instance.clearUser();
    return null;
  }
}
