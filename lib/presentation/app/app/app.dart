import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/router/app_route_observer.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/router/custom_navigator_observer.dart';
import 'package:calora/common/widgets/display/display_widget.dart';
import 'package:calora/common/widgets/system_ui/remove_status_bar_background.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/connectivity/connectivity_overlay.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:management/management.dart';

class App extends Managed<AppManager, AppState, AppEffect> {
  App({super.key});

  @override
  void listener(BuildContext context, AppManager manager, AppEffect effect) {
    super.listener(context, manager, effect);
    effect.mapOrNull(
      null,
      reLoginRequired: (_) => getIt<AppRouter>().replaceAll([AuthRoute()]),
    );
  }

  @override
  Widget builder(context, manager, state) {
    final appRouter = getIt<AppRouter>();
    return MaterialApp.router(
      title: 'Calora',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: context.theme,
      // SentryNavigatorObserver feeds navigation breadcrumbs and screen
      // names into every event and replay — without it a replay is a video
      // with no idea which screen it is showing.
      routerConfig: appRouter.config(
        navigatorObservers: () => [
          CustomNavigatorObserver(),
          SentryNavigatorObserver(),
          appRouteObserver,
        ],
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return KeyboardDismisser(
          child: ConnectivityOverlay(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                // Cap font scaling so devices set to very large system fonts
                // don't overflow fixed-height layouts (buttons / content
                // getting pushed off-screen). 1.1 keeps a little accessibility
                // headroom while staying within the app's layouts.
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.1,
                ),
              ),
              child: RemoveStatusBarBackground(
                child: DisplayWidget(key: ValueKey(state.language), child: child!),
              ),
            ),
          ),
        );
      },
    );
  }
}
