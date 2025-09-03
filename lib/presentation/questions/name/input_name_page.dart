import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/questions/name/management/input_name_management.dart';
import 'package:calora/presentation/questions/name/management/input_name_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:management/management.dart';

@RoutePage()
class InputNamePage
    extends Managed<InputNameManager, InputNameState, InputNameEffect> {
  const InputNamePage({super.key});

  @override
  Widget builder(context, manager, state) {
    return Center(child: Text("Comming soon"));
  }
}
