import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:calora/common/router/custom_navigator_observer.dart';
import 'package:calora/common/service/pedometer_service.dart';
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

  late final PedometerService? _pedometerService;

  @override
  void init(BuildContext context, AppManager manager) {
    super.init(context, manager);
    _initializePedometerService(manager);
  }

  @override
  void onFocusGained(BuildContext context, AppManager manager) {
    super.onFocusGained(context, manager);
    manager.startPeriodicDataSync();
    log('gaining focus');
  }

  @override
  void onFocusLost(BuildContext context, AppManager manager) {
    super.onFocusLost(context, manager);
    manager.stopPeriodicDataSync();
    log('loosing focus');
  }

  Future<void> _initializePedometerService(AppManager manager) async {
    try {
      _pedometerService = PedometerService(
        onTodayStepCountUpdated: (todaySteps) => manager.updateSteps(todaySteps),
        onError: (error) => debugPrint('StepsPageError: $error'),
      );
      final hasPermission = await _pedometerService!.checkPermissions();
      if (hasPermission) {
        manager.startPeriodicDataSync();
      } else {
        debugPrint('Pedometer permissions denied');
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize pedometer: $e\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _pedometerService?.dispose();
    super.dispose();
  }

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
