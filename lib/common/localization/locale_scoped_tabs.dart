import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Re-creates the tabs — and every tab's manager — when the app language
/// changes, then puts the user back on the tab they were on.
///
/// `'key'.tr()` doesn't subscribe a widget to locale changes, so tabs kept
/// alive in the IndexedStack, and strings managers cached in their state
/// (macro names, meal titles, server-localized content), would otherwise stay
/// in the old language until the app is restarted.
///
/// [builder] must call `onTabsRouter` from the tabs' `bottomNavigationBuilder`
/// so the active tab can be tracked and restored.
class LocaleScopedTabs extends StatefulWidget {
  const LocaleScopedTabs({super.key, required this.builder});

  final Widget Function(BuildContext context, ValueChanged<TabsRouter> onTabsRouter) builder;

  @override
  State<LocaleScopedTabs> createState() => _LocaleScopedTabsState();
}

class _LocaleScopedTabsState extends State<LocaleScopedTabs> {
  Locale? _locale;
  int _activeIndex = 0;
  int? _restoreIndex;

  void _onTabsRouter(TabsRouter router) {
    final restore = _restoreIndex;
    if (restore == null) {
      _activeIndex = router.activeIndex;
      return;
    }
    _restoreIndex = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && router.activeIndex != restore) router.setActiveIndex(restore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    if (_locale != null && _locale != locale) _restoreIndex = _activeIndex;
    _locale = locale;
    return KeyedSubtree(
      key: ValueKey(locale),
      child: widget.builder(context, _onTabsRouter),
    );
  }
}
