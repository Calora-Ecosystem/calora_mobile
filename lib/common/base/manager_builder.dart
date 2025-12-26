import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class ManagerBuilder<STATE, EFFECT> extends StatefulWidget {
  final Manager<STATE, EFFECT> manager;

  final List<dynamic> Function(STATE)? properties;

  final Widget Function(BuildContext context, STATE state) builder;

  const ManagerBuilder({
    super.key,
    required this.manager,
    required this.builder,
    this.properties,
  });

  @override
  State<ManagerBuilder<STATE, EFFECT>> createState() => _ManagerBuilderState<STATE, EFFECT>();
}

class _ManagerBuilderState<STATE, EFFECT> extends State<ManagerBuilder<STATE, EFFECT>> {
  late STATE _currentState;
  late StreamSubscription<STATE> _subscription;
  List<dynamic>? _lastProps;

  @override
  void initState() {
    super.initState();

    _currentState = widget.manager.state;

    _lastProps = widget.properties?.call(_currentState);

    _subscription = widget.manager.stateSubject.listen(
      (state) {
        try {
          final props = widget.properties?.call(state);

          if (!listEquals(props, _lastProps)) {
            _lastProps = props;
            setState(() => _currentState = state);
          }
        } catch (e, st) {
          if (kDebugMode) {
            print('[ManagerBuilder] Error processing state: $e\n$st');
          }
        }
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print('[ManagerBuilder] Stream error: $error\n$stackTrace');
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant ManagerBuilder<STATE, EFFECT> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.manager != widget.manager) {
      _subscription.cancel();
      _currentState = widget.manager.state;
      _lastProps = widget.properties?.call(_currentState);
      _subscription = widget.manager.stateSubject.listen((state) {
        final props = widget.properties?.call(state);
        if (!listEquals(props, _lastProps)) {
          _lastProps = props;
          setState(() => _currentState = state);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentState);
  }
}
