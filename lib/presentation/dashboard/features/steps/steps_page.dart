import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class StepsPage
    extends Managed<StepsManager, StepsState, StepsEffect> {
  const StepsPage({super.key});

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
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(child: Text("Coming soon")),
            ),
          ),
        ],
      ),
    );
  }
}