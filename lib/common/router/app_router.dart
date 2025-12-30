import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: SelectLanguageRoute.page),
    AutoRoute(page: OnboardingRoute.page),
    AutoRoute(page: AuthRoute.page),
    AutoRoute(page: VerifyRoute.page),
    AutoRoute(page: NotificationSettingsRoute.page),
    AutoRoute(page: QuestionsRoute.page),
    AutoRoute(page: CalculateRoute.page),
    AutoRoute(page: CaloriesRoute.page),
    AutoRoute(page: CourseRoute.page),
    AutoRoute(page: AccountDetailRoute.page),
    AutoRoute(
      page: DashboardRoute.page,
      children: [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: CaloriesRoute.page),
        AutoRoute(page: CourseRoute.page),
        AutoRoute(page: StepsRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
    AutoRoute(page: ProfileDetailRoute.page),
    AutoRoute(page: NormsRoute.page),
    AutoRoute(page: CourseQuestionsRoute.page),
    AutoRoute(page: LessonsRoute.page),
    AutoRoute(page: TasksRoute.page),
    AutoRoute(page: TaskRoute.page),
    AutoRoute(page: TasksProcessRoute.page),
    AutoRoute(page: FinishTaskRoute.page),
    AutoRoute(page: ProgressRoute.page),
    AutoRoute(page: InboxRoute.page),
    AutoRoute(page: CaloraAiRoute.page),
    AutoRoute(page: CaloraAiCalculateRoute.page),
    AutoRoute(page: VideoCourseBodyWidgetRoute.page),
    AutoRoute(page: MealsRoute.page),
    AutoRoute(page: AddMealsRoute.page),
    AutoRoute(page: DishesRoute.page),
    AutoRoute(page: UniversalCameraRoute.page),
    AutoRoute(page: UniversalProgressRoute.page),
  ];
}
