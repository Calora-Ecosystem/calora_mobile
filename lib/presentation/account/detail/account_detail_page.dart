import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/presentation/account/detail/management/account_detail_management.dart';
import 'package:calora/presentation/account/detail/management/account_detail_manager.dart';
import 'package:calora/presentation/app/app.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AccountDetailPage
    extends
        Managed<AccountDetailManager, AccountDetailState, AccountDetailEffect> {
  final Profile profile;

  AccountDetailPage({super.key, required this.profile});

  @override
  void init(context, manager) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      appBar: AppBar(title: ,),
      backgroundColor: context.colors.white,
      body: Column(children: []),
    );
  }
}
