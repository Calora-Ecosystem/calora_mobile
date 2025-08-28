import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/verify_management.dart';
import 'management/verify_manager.dart';

@RoutePage()
class VerifyPage extends Managed<VerifyManager, VerifyState, VerifyEffect> {
  const VerifyPage({super.key});
  
  @override
  void init(context, manager) {}
  
  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold();
  }
}
