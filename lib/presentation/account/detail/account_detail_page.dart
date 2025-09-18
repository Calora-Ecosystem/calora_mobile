import 'package:auto_route/annotations.dart';
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
    // TODO: implement builder
    throw UnimplementedError();
  }
}
