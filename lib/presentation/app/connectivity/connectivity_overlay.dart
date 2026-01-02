import 'dart:developer';

import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/presentation/app/connectivity/management/connectivity_management.dart';
import 'package:calora/presentation/app/connectivity/management/connectivity_manager.dart';
import 'package:calora/presentation/app/connectivity/widgets/connectivity_lost_sheet.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class ConnectivityOverlay extends Managed<ConnectivityManager, ConnectivityState, ConnectivityEffect> {
  final Widget child;
  ConnectivityOverlay({super.key, required this.child});

  OverlayEntry? _overlayEntry;
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  final ValueNotifier<bool> _shouldShowSheet = ValueNotifier<bool>(false);

  @override
  void listener(BuildContext context, ConnectivityManager manager, ConnectivityEffect effect) {
    super.listener(context, manager, effect);
    effect.when(showOverlay: _showOverlay, removeOverlay: _hideOverlay);
  }

  @override
  Widget builder(context, manager, state) {
    // Restore overlay state after hot reload or app resume if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only restore if we're disconnected and overlay isn't already shown
      if (!state.isConnected && _overlayEntry == null && !_shouldShowSheet.value) {
        log('[ConnectivityOverlay] Restoring overlay (disconnected state detected)');
        _showOverlay();
      }
    });

    return Overlay(
      key: _overlayKey,
      initialEntries: [OverlayEntry(builder: (context) => child)],
    );
  }

  void _showOverlay() {
    log(
      '[ConnectivityOverlay] _showOverlay called, current entry exists: ${_overlayEntry != null}, shouldShow: ${_shouldShowSheet.value}',
    );

    // If overlay already exists and is showing, just ensure it's visible
    if (_overlayEntry != null) {
      if (!_shouldShowSheet.value) {
        log('[ConnectivityOverlay] Re-showing existing overlay');
        _shouldShowSheet.value = true;
      }
      return;
    }

    final overlayState = _overlayKey.currentState;
    if (overlayState == null) {
      log('[ConnectivityOverlay] Overlay state is null, scheduling retry...');
      // Retry after a frame when overlay is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_overlayEntry == null) {
          _showOverlay();
        }
      });
      return;
    }

    log('[ConnectivityOverlay] Creating and inserting overlay entry.');
    _overlayEntry = OverlayEntry(
      builder: (_) => _AnimatedBottomSheet(
        shouldShow: _shouldShowSheet,
        child: ConnectivityLostSheet(),
      ),
    );

    overlayState.insert(_overlayEntry!);

    Future.microtask(() {
      log('[ConnectivityOverlay] Setting shouldShow to true');
      _shouldShowSheet.value = true;
    });
  }

  void _hideOverlay() {
    if (_overlayEntry == null) {
      log('[ConnectivityOverlay] _hideOverlay called but no overlay exists');
      return;
    }

    log('[ConnectivityOverlay] Hiding connectivity lost sheet.');

    _shouldShowSheet.value = false;

    Future.delayed(const Duration(milliseconds: 350), () {
      log('[ConnectivityOverlay] Removing overlay entry from tree');
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _shouldShowSheet.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}

class _AnimatedBottomSheet extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> shouldShow;

  const _AnimatedBottomSheet({required this.child, required this.shouldShow});

  @override
  State<_AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<_AnimatedBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    widget.shouldShow.addListener(_onShouldShowChanged);

    if (widget.shouldShow.value) {
      _controller.forward();
    }
  }

  void _onShouldShowChanged() {
    if (widget.shouldShow.value) {
      log('[_AnimatedBottomSheet] Animating in');
      _controller.forward();
    } else {
      log('[_AnimatedBottomSheet] Animating out');
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.shouldShow.removeListener(_onShouldShowChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black.withOpacityLevel(_fadeAnimation.value),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0, 1 - _slideAnimation.value),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacityLevel(0.2),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
