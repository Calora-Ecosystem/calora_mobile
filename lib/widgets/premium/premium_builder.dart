import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:management/management.dart';

class PremiumBuilder extends StatelessWidget {
  const PremiumBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool isPremium) builder;

  @override
  Widget build(BuildContext context) {
    return ManagerBuilder<AppState, AppEffect>(
      manager: context.read<AppManager>(),
      properties: (state) => [state.isUserPremium],
      builder: (context, state) => builder(context, state.isUserPremium),
    );
  }
}
