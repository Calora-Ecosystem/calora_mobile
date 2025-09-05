import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class HomePage
    extends Managed<HomeManager, HomeState, HomeEffect> {
  const HomePage({super.key});

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