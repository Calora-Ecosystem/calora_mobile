import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/coins/widgets/market_item_card.dart';
import 'package:calora/presentation/coins/widgets/step_coin_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Lays the new wallet / shop widgets out at a small phone width and runs the
/// banner animation for a few frames — any overflow or layout error fails.
void main() {
  setUpAll(() => GetIt.instance.registerSingleton(DefaultThemeColors()));

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );

  testWidgets('step coin banner animates without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        const StepCoinBanner(
          stepsPerCoin: 1000,
          maxDailyCoins: 22,
          todayCoins: 8,
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(StepCoinBanner), findsOneWidget);
  });

  testWidgets('tariff grid lays out', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const tariffs = [
      (1, 'mi_premium_7', 150, 7),
      (2, 'mi_premium_30', 300, 30),
      (3, 'mi_premium_75', 600, 75),
      (4, 'mi_premium_120', 900, 120),
    ];

    await tester.pumpWidget(
      wrap(
        GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 168,
          ),
          children: [
            for (final t in tariffs)
              MarketItemCard(
                item: MarketItem(
                  id: t.$1,
                  title: t.$2,
                  subtitle: '${t.$2}_sub',
                  priceCoins: t.$3,
                  category: MarketCategory.tariff,
                  rewardType: MarketRewardType.premiumDays,
                  rewardValue: t.$4,
                ),
                onBuy: () {},
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(MarketItemCard), findsNWidgets(4));
  });
}
