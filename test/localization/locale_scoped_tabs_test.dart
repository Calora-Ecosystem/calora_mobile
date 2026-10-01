import 'package:auto_route/auto_route.dart';
import 'package:calora/common/localization/locale_scoped_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Switching the language on one tab must re-translate the other (hidden,
/// kept-alive) tabs and strings a tab cached in its state — and leave the
/// user on the tab they were on. Mirrors the dashboard: AutoTabsScaffold
/// inside [LocaleScopedTabs].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('language switch re-translates every tab and keeps the active one', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('uz', 'UZ'), Locale('ru', 'RU')],
          path: 'unused',
          assetLoader: const _Loader(),
          startLocale: const Locale('uz', 'UZ'),
          saveLocale: false,
          child: _App(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('A:Saqlash'), findsOneWidget);

    // Open the second tab (like Profile) and change the language there.
    AutoTabsRouter.of(tester.element(find.text('active:0'))).setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('B:Saqlash'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('switch'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('active:1'), findsOneWidget, reason: 'stays on the tab the user was on');
    expect(find.text('B:Сохранить'), findsOneWidget, reason: 'state-cached text re-created');
    expect(find.text('A:Сохранить', skipOffstage: false), findsOneWidget, reason: 'hidden tab re-translated');
    expect(find.textContaining('Saqlash', skipOffstage: false), findsNothing);
  });
}

class _Loader extends AssetLoader {
  const _Loader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      locale.languageCode == 'ru' ? {'save': 'Сохранить'} : {'save': 'Saqlash'};
}

class _App extends StatelessWidget {
  _App();

  final _router = _Router();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    localizationsDelegates: context.localizationDelegates,
    supportedLocales: context.supportedLocales,
    locale: context.locale,
    routerConfig: _router.config(),
  );
}

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo('Dash', builder: (_) => const _Dash()),
      initial: true,
      children: [
        AutoRoute(page: PageInfo('TabA', builder: (_) => const _TabA())),
        AutoRoute(page: PageInfo('TabB', builder: (_) => const _TabB())),
      ],
    ),
  ];
}

class _Dash extends StatelessWidget {
  const _Dash();

  @override
  Widget build(BuildContext context) => LocaleScopedTabs(
    builder: (context, onTabsRouter) => AutoTabsScaffold(
      routes: const [PageRouteInfo('TabA'), PageRouteInfo('TabB')],
      bottomNavigationBuilder: (context, tabsRouter) {
        onTabsRouter(tabsRouter);
        return Text('active:${tabsRouter.activeIndex}');
      },
    ),
  );
}

class _TabA extends StatelessWidget {
  const _TabA();

  @override
  Widget build(BuildContext context) => Text('A:${'save'.tr()}');
}

/// Caches a translated string in state, like a manager does with `Strings.*`.
class _TabB extends StatefulWidget {
  const _TabB();

  @override
  State<_TabB> createState() => _TabBState();
}

class _TabBState extends State<_TabB> {
  late final String _cached = 'save'.tr();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('B:$_cached'),
      TextButton(
        onPressed: () => context.setLocale(const Locale('ru', 'RU')),
        child: const Text('switch'),
      ),
    ],
  );
}
