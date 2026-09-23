import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:calora/presentation/coins/management/coins_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management/management.dart';

@RoutePage()
class ExchangePage extends Managed<CoinsManager, CoinsState, CoinsEffect> {
  ExchangePage({super.key});

  @override
  void listener(
    BuildContext context,
    CoinsManager manager,
    CoinsEffect effect,
  ) {
    effect.mapOrNull(
      exchanged: (e) {
        CustomSnackBar.show(
          context,
          'exchange_success'.tr(namedArgs: {'coins': '${e.coins}'}),
        );
        context.router.maybePop();
      },
      nothingToExchange: (_) =>
          CustomSnackBar.show(context, 'nothing_to_exchange'.tr()),
      failed: (_) => CustomSnackBar.show(context, 'something_went_wrong'.tr()),
    );
  }

  @override
  Widget builder(BuildContext context, CoinsManager manager, CoinsState state) {
    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: 'exchange_title'.tr(),
        onBack: () => context.router.maybePop(),
      ),
      body: _ExchangeBody(state: state, onExchange: manager.exchange),
    );
  }
}

/// The converter itself — a "give / get" pair like a currency exchange, with a
/// live coin amount so the user feels the trade happening as they type.
class _ExchangeBody extends StatefulWidget {
  const _ExchangeBody({required this.state, required this.onExchange});

  final CoinsState state;
  final void Function(int calora) onExchange;

  @override
  State<_ExchangeBody> createState() => _ExchangeBodyState();
}

class _ExchangeBodyState extends State<_ExchangeBody> {
  final _controller = TextEditingController();

  int get _perCoin => widget.state.caloraPerCoin;

  int get _calora => int.tryParse(_controller.text) ?? 0;

  int get _coins => _calora ~/ _perCoin;

  bool get _canExchange =>
      _coins >= 1 && _calora <= widget.state.availableCalora;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setMax() {
    final maxCalora = widget.state.maxExchangeableCoins * _perCoin;
    _controller.text = '$maxCalora';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _giveCard(context),
                const SizedBox(height: 8),
                _getCard(context),
              ],
            ),
            _swapBadge(context),
          ],
        ),
        const SizedBox(height: 16),
        _rateRow(context),
        const SizedBox(height: 24),
        Button(
          text: 'exchange_action'.tr(),
          enabled: _canExchange && !widget.state.busy,
          onPressed: () => _confirmExchange(context),
        ),
      ],
    );
  }

  Widget _giveCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'exchange_give'.tr().text(13, 16, 500).c(colors.textSub),
          const SizedBox(height: 10),
          Row(
            children: [
              _currencyChip(
                context,
                Assets.images.caloraLogo.image(
                  height: 18,
                  color: context.colors.accentSub,
                  colorBlendMode: BlendMode.srcIn,
                ),
                'calora_unit'.tr(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 26,
                    height: 30 / 26,
                    fontWeight: FontWeight.w700,
                    color: colors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              'exchange_available'
                  .tr(namedArgs: {'amount': '${widget.state.availableCalora}'})
                  .text(12, 15, 400)
                  .c(colors.textSub),
              const Spacer(),
              GestureDetector(
                onTap: _setMax,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: 'exchange_max'
                      .tr()
                      .text(12, 14, 600)
                      .c(colors.accentSub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'exchange_get'.tr().text(13, 16, 500).c(colors.textSub),
          const SizedBox(height: 10),
          Row(
            children: [
              _currencyChip(
                context,
                Icon(
                  Icons.monetization_on_rounded,
                  size: 18,
                  color: colors.accentSub,
                ),
                'coin_unit'.tr(),
              ),
              const Spacer(),
              '$_coins'.text(26, 30, 700).c(colors.accentSub),
            ],
          ),
        ],
      ),
    );
  }

  /// The circular swap glyph seated between the two cards.
  Widget _swapBadge(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: colors.accentSub,
        shape: BoxShape.circle,
        border: Border.all(color: colors.softGray, width: 3),
      ),
      child: Icon(Icons.swap_vert_rounded, color: colors.textWhite, size: 22),
    );
  }

  Widget _currencyChip(BuildContext context, Widget icon, String label) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundElevation,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          label.text(14, 18, 600).c(colors.textStrong),
        ],
      ),
    );
  }

  /// "Are you sure?" gate before the irreversible exchange.
  void _confirmExchange(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.white,
        title: 'exchange_confirm_title'
            .tr()
            .text(17, 22, 600)
            .c(colors.textStrong),
        content: 'exchange_confirm_msg'
            .tr(namedArgs: {'calora': '$_calora', 'coins': '$_coins'})
            .text(14, 20, 400)
            .c(colors.textSub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Strings.close.text(14, 18, 500).c(colors.textSub),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onExchange(_calora);
            },
            child: 'exchange_agree'.tr().text(14, 18, 600).c(colors.accentSub),
          ),
        ],
      ),
    );
  }

  Widget _rateRow(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: 'exchange_rate'
          .tr(namedArgs: {'calora': '$_perCoin'})
          .text(13, 16, 500)
          .c(colors.textSub),
    );
  }
}
