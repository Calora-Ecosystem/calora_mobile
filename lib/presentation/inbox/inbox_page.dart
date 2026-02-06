import 'dart:developer';

import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/inbox/management/inbox_management.dart';
import 'package:calora/presentation/inbox/management/inbox_manager.dart';
import 'package:calora/presentation/inbox/widget/notification_item.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:management/management.dart';

@RoutePage()
class InboxPage extends Managed<InboxManager, InboxState, InboxEffect> {
  const InboxPage({super.key});

  @override
  void init(context, manager) {
    manager.initializeNotifications();
  }

  @override
  Widget builder(BuildContext context, InboxManager manager, InboxState state) {
    log('${state.notificationController?.itemList}');
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.notification,
        // trailing: Padding(
        //   padding: const EdgeInsets.only(right: 12),
        //   child: GestureDetector(
        //     onTap: () {},
        //     child: Assets.icons.messageDone.svg(),
        //   ),
        // ),
      ),
      body: PagedListView<int, model.Notification>(
        pagingController: manager.pagingController,
        builderDelegate: PagedChildBuilderDelegate<model.Notification>(
          itemBuilder: (context, notification, index) {
            return NotificationItem(notification: notification);
          },
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Strings.notificationFailed.text(16, 20, 500).c(Colors.grey),
              ],
            ),
          ),
          noItemsFoundIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Assets.icons.notification.svg(width: 64, height: 64),
                const SizedBox(height: 16),
                Strings.noNotifications.text(16, 20, 500).c(Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
