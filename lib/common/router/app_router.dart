import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SelectLanguageRoute.page),
    AutoRoute(page: OnboardingRoute.page),
    AutoRoute(page: AuthRoute.page),
    AutoRoute(page: VerifyRoute.page),
    AutoRoute(page: InputNameRoute.page),
    AutoRoute(page: CaloriesRoute.page),
    AutoRoute(page: CourseRoute.page),
    AutoRoute(
      page: DashboardRoute.page,
      initial: true,
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: CaloriesRoute.page),
        AutoRoute(page: CourseRoute.page),
        AutoRoute(page: StepsRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
  ];
}
