import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:calora/presentation/account/detail/management/account_detail_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/detail/info/detail_info_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AccountDetailPage
    extends
        Managed<AccountDetailManager, AccountDetailState, AccountDetailEffect> {
  final Profile profile;

  AccountDetailPage({super.key, required this.profile});

  @override
  void init(context, manager) {
    manager.getProfileDetail();
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.accountInformation,
        onBack: () {
          _back(context);
        },
      ),
      body: _uiBuilder(state, context),
    );
  }

  Widget _uiBuilder(AccountDetailState state, BuildContext context) {
    if (state.loading) {
      return Loadable(
        builder: (context) {
          return SizedBox();
        },
      );
    } else {
      return ListView.separated(
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: context.colors.strokeSoft),
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: state.detailInfos?.length ?? 1,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final detailsInfo = state.detailInfos?[index] ?? DetailInfo();
          return DetailInfoItemBuilder(
            detailInfo: detailsInfo,
            onClickItem: (data) {},
          );
        },
      );
    }
  }

  void _back(BuildContext context) {
    return context.router.pop();
  }
}
