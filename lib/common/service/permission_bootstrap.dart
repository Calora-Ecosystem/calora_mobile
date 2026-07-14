import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Front-loads the app's *system* permissions so their dialogs appear first on
/// launch — before the feature tour and step tracking start.
///
/// Only the always-needed background permissions are requested up front
/// (notifications + activity/motion for step tracking). Feature-specific
/// permissions (camera for scan, microphone for voice) are intentionally left
/// on-demand — they are asked the first time the user opens that feature.
///
/// Runs exactly once per process; concurrent/later callers await the same run.
class PermissionBootstrap {
  PermissionBootstrap._();

  static final PermissionBootstrap instance = PermissionBootstrap._();

  Future<void>? _run;
  final Completer<void> _firstRunPromptsDone = Completer<void>();

  /// Requests the up-front runtime permissions (notification + activity/motion)
  /// in sequence. Idempotent — awaiting resolves once the dialogs are answered.
  Future<void> ensureRequested() => _run ??= _requestAll();

  /// Resolves once every first-run system prompt has been handled — the
  /// permissions above *and* the interactive prompts the dashboard drives
  /// (Health Connect / battery-optimization). The feature tour waits on this so
  /// it never starts underneath a system prompt.
  Future<void> get firstRunPromptsDone => _firstRunPromptsDone.future;

  /// Signals that the dashboard has finished driving the interactive first-run
  /// prompts (battery / health). Safe to call more than once.
  void markFirstRunPromptsDone() {
    if (!_firstRunPromptsDone.isCompleted) _firstRunPromptsDone.complete();
  }

  Future<void> _requestAll() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // Sequentially (awaited) so each system dialog is shown and dismissed
    // before the next is requested, rather than stacking.

    // Meal / water reminder notifications.
    await _ask(Permission.notification);

    // Step tracking — activity recognition on Android, motion on iOS.
    await _ask(
      Platform.isIOS ? Permission.sensors : Permission.activityRecognition,
    );
  }

  Future<void> _ask(Permission permission) async {
    try {
      // `request()` is a no-op (no dialog) when already granted or permanently
      // denied, so it's safe to call every launch.
      await permission.request();
    } catch (_) {
      // One unavailable/failing permission must not block the rest.
    }
  }
}
