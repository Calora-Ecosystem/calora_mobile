import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SelectLanguageRoute.page, initial: true),
    AutoRoute(page: OnboardingRoute.page),
    AutoRoute(page: AuthRoute.page),
    AutoRoute(page: VerifyRoute.page),
    AutoRoute(page: InputNameRoute.page),
  ];
}
