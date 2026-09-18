import 'dart:async';

import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/widgets/info/dish_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.onSave, required this.onClosed});

  final Future<bool> Function(double amount) onSave;
  final ValueChanged<bool?> onClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final saved = await context.showAppBottomSheet<bool>(
              child: DishInfoPage(
                foodItem: const FoodModel(
                  name: 'Plov',
                  categoryId: 1,
                  coverUrl: '',
                  metrics: [],
                ),
                isFavourite: false,
                onFavouriteChanged: (_) {},
                onSave: onSave,
              ),
            );
            onClosed(saved);
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() => GetIt.instance.registerSingleton(DefaultThemeColors()));

  Future<void> openSheet(
    WidgetTester tester, {
    required Future<bool> Function(double amount) onSave,
    ValueChanged<bool?>? onClosed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _SheetHost(onSave: onSave, onClosed: onClosed ?? (_) {}),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Button));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'saves once when Save is tapped again while a save is in flight',
    (tester) async {
      final pendingSave = Completer<bool>();
      var saves = 0;
      var closed = false;
      bool? result;
      await openSheet(
        tester,
        onSave: (_) {
          saves++;
          return pendingSave.future;
        },
        onClosed: (value) {
          closed = true;
          result = value;
        },
      );

      await tester.tap(find.byType(Button));
      await tester.pump();
      await tester.tap(find.byType(Button), warnIfMissed: false);
      await tester.pump();

      expect(saves, 1);
      expect(closed, isFalse);

      pendingSave.complete(true);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isTrue);
      expect(find.byType(DishInfoPage), findsNothing);
    },
  );

  testWidgets('closes with false when the save fails', (tester) async {
    bool? result;
    await openSheet(
      tester,
      onSave: (_) async => false,
      onClosed: (value) => result = value,
    );

    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(DishInfoPage), findsNothing);
  });

  testWidgets('never pops a route pushed over the sheet during the save', (
    tester,
  ) async {
    final pendingSave = Completer<bool>();
    await openSheet(tester, onSave: (_) => pendingSave.future);

    await tester.tap(find.byType(Button));
    await tester.pump();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(builder: (_) => const Text('login')));
    await tester.pumpAndSettle();

    pendingSave.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });
}
