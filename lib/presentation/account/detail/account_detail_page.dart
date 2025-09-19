import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:calora/presentation/account/detail/management/account_detail_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AccountDetailPage
    extends
        Managed<AccountDetailManager, AccountDetailState, AccountDetailEffect> {
  final String profileId;

  AccountDetailPage({super.key, required this.profileId});

  @override
  void init(context, manager) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Container(width: double.infinity, height: double.infinity),
          ),
        ],
      ),
    );
  }
}
