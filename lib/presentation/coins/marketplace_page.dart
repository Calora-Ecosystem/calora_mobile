import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:calora/presentation/coins/management/coins_manager.dart';
import 'package:calora/presentation/coins/widgets/market_item_card.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management/management.dart';

@RoutePage()
class MarketplacePage extends Managed<CoinsManager, CoinsState, CoinsEffect> {
  MarketplacePage({super.key});

  @override
  void listener(
    BuildContext context,
    CoinsManager manager,
    CoinsEffect effect,
  ) {
    effect.mapOrNull(
      purchased: (e) {
        CustomSnackBar.show(
          context,
          'purchase_success'.tr(namedArgs: {'title': e.item.title.tr()}),
        );
        if (e.code != null) _showCode(context, e.code!);
      },
      insufficientCoins: (_) =>
          CustomSnackBar.show(context, 'insufficient_coins'.tr()),
      failed: (_) => CustomSnackBar.show(context, 'something_went_wrong'.tr()),
    );
  }

  @override
  Widget builder(BuildContext context, CoinsManager manager, CoinsState state) {
    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: 'marketplace_title'.tr(),
        onBack: () => context.router.maybePop(),
        trailing: _balanceChip(context, state.balance),
      ),
      body: _MarketBody(state: state, onBuy: manager.purchase),
    );
  }

  /// Coupon / voucher rewards come with a code the user needs later (a coupon
  /// is entered as a promo code at checkout), so it's shown and copyable.
  void _showCode(BuildContext context, String code) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.white,
        title: 'your_code'.tr().text(17, 22, 600).c(colors.textStrong),
        content: SelectableText(
          code,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.accentSub,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.of(dialogContext).pop();
              CustomSnackBar.show(context, 'copied'.tr());
            },
            child: 'copy_action'.tr().text(14, 18, 600).c(colors.accentSub),
          ),
        ],
      ),
    );
  }

  Widget _balanceChip(BuildContext context, int balance) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: 15,
            color: colors.accentSub,
          ),
          const SizedBox(width: 4),
          '$balance'.text(13, 16, 600).c(colors.accentSub),
        ],
      ),
    );
  }
}

/// Holds the selected category tab locally — a pure view concern that doesn't
/// belong in the shared coins state.
class _MarketBody extends StatefulWidget {
  const _MarketBody({required this.state, required this.onBuy});

  final CoinsState state;
  final void Function(MarketItem item) onBuy;

  @override
  State<_MarketBody> createState() => _MarketBodyState();
}

class _MarketBodyState extends State<_MarketBody> {
  MarketCategory _category = MarketCategory.tariff;

  static const _allTabs = [
    (MarketCategory.tariff, 'market_cat_tariff'),
    (MarketCategory.voucher, 'market_cat_voucher'),
    (MarketCategory.boost, 'market_cat_boost'),
  ];

  /// Only categories the server actually sells right now.
  List<(MarketCategory, String)> get _tabs {
    final present = widget.state.catalog.map((i) => i.category).toSet();
    final tabs = _allTabs.where((t) => present.contains(t.$1)).toList();
    return tabs.isEmpty ? _allTabs.take(1).toList() : tabs;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (!tabs.any((t) => t.$1 == _category)) _category = tabs.first.$1;
    final items = widget.state.catalog
        .where((i) => i.category == _category)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildSegment(context, tabs),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 168,
          ),
          itemBuilder: (context, index) => MarketItemCard(
            item: items[index],
            onBuy: () => widget.onBuy(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSegment(
    BuildContext context,
    List<(MarketCategory, String)> tabs,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.backgroundElevation,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _category = tab.$1),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _category == tab.$1 ? colors.white : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: tab.$2
                      .tr()
                      .text(13, 16, 500)
                      .c(
                        _category == tab.$1
                            ? colors.textStrong
                            : colors.neutral600Secondary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
