import 'package:flutter/widgets.dart';

/// Root-navigator route observer. Lets a page detect when it becomes visible
/// again after a route above it (e.g. the premium paywall pushed on top of the
/// dashboard right after registration) is dismissed — so first-run permission
/// prompts fire on the home screen, not underneath the paywall.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
