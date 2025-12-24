import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/inbox/management/inbox_management.dart';
import 'package:calora/presentation/inbox/management/inbox_manager.dart';

@RoutePage()
class InboxPage extends Managed<InboxManager, InboxState, InboxEffect> {
  const InboxPage({super.key});

  @override
  Widget builder(BuildContext context, InboxManager manager, InboxState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.notification,
        trailing: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(onTap: () {}, child: Assets.icons.messageDone.svg()),
        ),
      ),
    );
  }
}
