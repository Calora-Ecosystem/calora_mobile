import 'package:flutter/material.dart';

class AppLifecycleObserverServer with WidgetsBindingObserver {
  final VoidCallback onResumed;
  AppLifecycleObserverServer({required this.onResumed});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}