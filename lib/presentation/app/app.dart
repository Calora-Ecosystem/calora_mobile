import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/flavor/flavor_config.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:calora/common/widgets/display/display_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:management/management.dart';

import 'management/app_management.dart';
import 'management/app_manager.dart';

@RoutePage()
class App extends Managed<AppManager, AppState, AppEffect> {
  App({super.key});

  final _appRouter = AppRouter();

  @override
  void init(BuildContext context, AppManager manager) {
    super.init(context, manager);
  }

  @override
  Widget builder(context, manager, state) {
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
              routerConfig: _appRouter.config(
                deepLinkBuilder: (_) =>
                    DeepLink([_initialRoute()]),
              ),
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: mediaQuery.textScaler.clamp(
                      minScaleFactor: 0.8,
                      maxScaleFactor: 1.2,
                    ),
                  ),
                  child: DisplayWidget(
                    key: ValueKey(state.language),
                    child: child!,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  PageRouteInfo _initialRoute() {
    bool isLogin = FlavorConfig.isLogin;

    if (isLogin) {
      return DashboardRoute();
    } else {
      return DashboardRoute();
    }
  }
}
