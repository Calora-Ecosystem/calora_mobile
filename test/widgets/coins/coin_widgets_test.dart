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

  testWidgets('tariff cards lay out (affordable, popular, missing coins)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const items = [
      MarketItem(
        id: 1,
        title: 'mi_premium_7',
        subtitle: 'mi_premium_7_sub',
        priceCoins: 150,
        category: MarketCategory.tariff,
        rewardType: MarketRewardType.premiumDays,
        rewardValue: 7,
      ),
      MarketItem(
        id: 2,
        title: 'mi_premium_30',
        subtitle: 'mi_premium_30_sub',
        priceCoins: 300,
        category: MarketCategory.tariff,
        rewardType: MarketRewardType.premiumDays,
        rewardValue: 30,
        isPopular: true,
      ),
      MarketItem(
        id: 4,
        title: 'mi_premium_120',
        subtitle: 'mi_premium_120_sub',
        priceCoins: 900,
        category: MarketCategory.tariff,
        rewardType: MarketRewardType.premiumDays,
        rewardValue: 120,
      ),
    ];

    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            for (final item in items)
              MarketItemCard(item: item, balance: 320, onBuy: () {}),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(MarketItemCard), findsNWidgets(3));
  });
}
