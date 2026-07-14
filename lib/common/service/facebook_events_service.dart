import 'dart:developer';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around the Meta (Facebook) SDK App Events.
///
/// The SDK is auto-initialized natively from the App ID / Client Token in
/// `AndroidManifest.xml` (via `res/values/strings.xml`) and iOS `Info.plist`.
/// This service just enables advertiser tracking and lets the app log the
/// custom conversion events Meta uses for audience building and ad targeting.
class FacebookEventsService {
  FacebookEventsService._();

  static final FacebookEventsService instance = FacebookEventsService._();

  final FacebookAppEvents _fb = FacebookAppEvents();

  /// Call once during app startup (after the native SDK is available).
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      // Automatic install / app-open / session events power Meta targeting.
      await _fb.setAutoLogAppEventsEnabled(true);
      // Attach the advertiser ID (GAID on Android; IDFA on iOS, gated by the
      // system App Tracking Transparency prompt) so events are attributable
      // for ad delivery.
      await _fb.setAdvertiserIdCollectionEnabled(true);
    } catch (e) {
      // Never let analytics setup break app startup (e.g. before the real
      // App ID / Client Token have been filled in).
      log('[FB] init failed: $e');
    }
  }

  /// Show the iOS App Tracking Transparency prompt (no-op on Android / web).
  ///
  /// Must run while the app is active (i.e. after the first frame), otherwise
  /// iOS silently skips the dialog. The Meta SDK reads the resulting ATT
  /// status to decide whether it may use the IDFA for ad attribution.
  Future<void> requestTracking() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      log('[FB] ATT request failed: $e');
    }
  }

  /// Log an arbitrary standard or custom event.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) async {
    if (kIsWeb) return;
    try {
      await _fb.logEvent(
        name: name,
        parameters: parameters,
        valueToSum: valueToSum,
      );
    } catch (e) {
      log('[FB] logEvent "$name" failed: $e');
    }
  }

  /// Convenience for the standard "complete registration" conversion.
  Future<void> logCompletedRegistration({String? method}) async {
    if (kIsWeb) return;
    try {
      await _fb.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {if (method != null) 'fb_registration_method': method},
      );
    } catch (e) {
      log('[FB] logCompletedRegistration failed: $e');
    }
  }
}
