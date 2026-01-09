import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class CustomNavigatorObserver extends AutoRouteObserver {
  final Logger _logger = getIt<Logger>();

  @override
  void didPush(Route route, Route? previousRoute) {
    _logger.d('New route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _logger.d('Route popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _logger.d(
      'Route replaced: ${oldRoute?.settings.name} by ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _logger.d('Route removed: ${route.settings.name}');
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _logger.d('User gesture started on route: ${route.settings.name}');
  }

  @override
  void didStopUserGesture() {
    _logger.d('User gesture stopped.');
  }
}
