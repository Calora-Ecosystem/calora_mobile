import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:calora/common/router/custom_navigator_observer.dart';
import 'package:calora/common/widgets/display/display_widget.dart';
import 'package:calora/common/widgets/system_ui/remove_status_bar_background.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/connectivity/connectivity_overlay.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:management/management.dart';

@RoutePage()
class App extends Managed<AppManager, AppState, AppEffect> {
  App({super.key});

  @override
  Widget builder(context, manager, state) {
    final appRouter = getIt<AppRouter>();
    return EasyLocalization(
      supportedLocales: Strings.supportedLocales,
      path: Assets.localization.translations,
      assetLoader: CsvAssetLoader(),
      fallbackLocale: const Locale('uz', 'UZ'),
      startLocale: const Locale('uz', 'UZ'),
      child: Builder(
        builder: (context) {
          return KeyboardDismisser(
            child: MaterialApp.router(
              title: 'Calora',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: context.theme,
              routerConfig: appRouter.config(navigatorObservers: () => [CustomNavigatorObserver()]),
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return ConnectivityOverlay(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: mediaQuery.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
                    ),
                    child: RemoveStatusBarBackground(
                      child: DisplayWidget(key: ValueKey(state.language), child: child!),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
