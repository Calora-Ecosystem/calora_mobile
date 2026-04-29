import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.config.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies({bool isBackground = false}) async {
  await getIt.init();
  if (!isBackground) {
    final appRouter = AppRouter();
    getIt.registerSingleton<StackRouter>(appRouter);
  }
}
