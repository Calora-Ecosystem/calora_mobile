import 'package:auto_route/annotations.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class NotificationSettingsPage
    extends
        Managed<
          NotificationSettingsManager,
          NotificationSettingsState,
          NotificationSettingsEffect
        > {
  @override
  void init(context, manager) {}

  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    // TODO: implement builder
    throw UnimplementedError();
  }
}
