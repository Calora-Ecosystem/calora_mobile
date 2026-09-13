import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Meta (Facebook) App Events — the conversion signal behind Meta App Ads.
///
/// The native SDK initializes itself from the App ID / Client Token declared
/// in `android/app/src/main/res/values/strings.xml` (referenced by
/// `AndroidManifest.xml`) and `ios/Runner/Info.plist`. Nothing here creates
/// the SDK; this service only configures it and reports conversions.
///
/// Call order at startup matters and is fixed by [init] / [start]:
///
///  1. [init] before `runApp` — flips the SDK's auto-logging and advertiser-ID
///     switches on while nothing is on screen yet.
///  2. [start] after the first frame — shows the iOS ATT prompt (which iOS
///     ignores unless the app is *active*), then logs the app activation.
///
/// Every method is failure-tolerant: analytics must never take the app down,
/// so each call is wrapped and logs instead of throwing.
class FacebookAnalyticsService {
  FacebookAnalyticsService._();

  static final FacebookAnalyticsService instance = FacebookAnalyticsService._();

  final FacebookAppEvents _fb = FacebookAppEvents();

  /// Keys of conversions already reported this process, so a retry / resume /
  /// poll can't bill Meta twice for the same order. Meta optimizes bidding on
  /// these events, so a duplicate Purchase is worse than a missing one.
  final Set<String> _alreadyLogged = <String>{};

  /// `Platform` throws on web, so `kIsWeb` has to be checked first.
  bool get _enabled => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ───────────────────────────── lifecycle ─────────────────────────────

  /// Configure the SDK. Safe to call before `runApp`.
  Future<void> init() async {
    if (!_enabled) return;
    try {
      // Install / app-open / session events — these are what Meta's App Ads
      // delivery model is trained on, so they stay on.
      await _fb.setAutoLogAppEventsEnabled(true);
      // Attach the advertiser ID (GAID on Android, IDFA on iOS). On iOS the
      // IDFA is still gated by ATT below; this only permits its use.
      await _fb.setAdvertiserIdCollectionEnabled(true);
      if (kDebugMode) await _fb.setDebugLoggingEnabled(true);
    } catch (e) {
      log('[Meta] init failed: $e');
    }
  }

  /// Post-first-frame startup: ATT prompt, then activation.
  ///
  /// Ordered deliberately — resolving tracking consent *before* the activation
  /// event means that event carries the right consent state on iOS instead of
  /// being attributed as non-tracked.
  Future<void> start() async {
    if (!_enabled) return;
    await requestTracking();
    await logActivatedApp();
  }

  /// Show the iOS App Tracking Transparency prompt. No-op on Android/web.
  ///
  /// iOS silently drops the request unless the app is in the *active* state,
  /// which it is not yet during the first frame — hence the bounded wait.
  /// Returns the resulting status (always [TrackingStatus.notSupported] off
  /// iOS) so callers can branch on consent if they ever need to.
  Future<TrackingStatus> requestTracking() async {
    if (!_enabled || !Platform.isIOS) return TrackingStatus.notSupported;
    try {
      await _waitUntilResumed();

      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return status;

      return await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (e) {
      log('[Meta] ATT request failed: $e');
      return TrackingStatus.notDetermined;
    }
  }

  /// Waits (briefly) for the app to reach `resumed`, the only state in which
  /// iOS will actually present the ATT dialog. Gives up after ~3s rather than
  /// blocking startup forever if the app launches into the background.
  Future<void> _waitUntilResumed() async {
    const step = Duration(milliseconds: 150);
    for (var i = 0; i < 20; i++) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        // A short settle after `resumed`: the dialog is dropped if it is
        // requested in the same turn the app becomes active.
        await Future<void>.delayed(step);
        return;
      }
      await Future<void>.delayed(step);
    }
  }

  /// Explicit app-activation event.
  ///
  /// Redundant while `FacebookAutoLogAppEventsEnabled` (iOS) /
  /// `com.facebook.sdk.AutoLogAppEventsEnabled` (Android) are YES — which they
  /// are — but harmless, and it keeps activation reported if auto-logging is
  /// ever turned off for consent reasons.
  Future<void> logActivatedApp() => _guard('activateApp', _fb.activateApp);

  /// Associates subsequent events with your own user id, improving Meta's
  /// match rate. Call after sign-in; pair with [clearUser] on sign-out.
  Future<void> setUserId(String userId) =>
      _guard('setUserID', () => _fb.setUserID(userId));

  /// Drops the user id and any user data set on the SDK. Call on sign-out.
  Future<void> clearUser() => _guard('clearUser', () async {
    await _fb.clearUserID();
    await _fb.clearUserData();
  });

  /// Forces a flush of buffered events. The SDK batches by default; use this
  /// only when an event must land before the app may be killed.
  Future<void> flush() => _guard('flush', _fb.flush);

  // ────────────────────────────── funnel ───────────────────────────────

  /// `CompleteRegistration` — a new account was created.
  ///
  /// [method] is how they signed up ("google", "apple", "phone", "email") and
  /// shows up in Ads Manager as a breakdown, so keep the values stable.
  Future<void> logCompleteRegistration({required String method}) => _guard(
    'CompleteRegistration',
    () => _fb.logCompletedRegistration(registrationMethod: method),
  );

  /// `ViewContent` — the user opened something you want to retarget on
  /// (a paywall, a dish, a lesson).
  ///
  /// [price]/[currency] are optional but required for ROAS optimization, so
  /// pass them whenever the content carries a price.
  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    double? price,
    String? currency,
    Map<String, dynamic>? content,
  }) => _guard(
    'ViewContent',
    () => _fb.logViewContent(
      id: contentId,
      type: contentType,
      price: price,
      currency: currency,
      content: content,
    ),
  );

  /// `Search` — the user searched inside the app.
  Future<void> logSearch({
    required String searchString,
    String? contentType,
  }) => _guard(
    'Search',
    () => _fb.logSearched(
      searchString: searchString,
      contentType: contentType,
    ),
  );

  /// `AddToCart` — purchase intent short of checkout (e.g. picking a plan).
  ///
  /// Meta requires id, type, price and currency on this one.
  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required double price,
    required String currency,
    Map<String, dynamic>? content,
  }) => _guard(
    'AddToCart',
    () => _fb.logAddToCart(
      id: contentId,
      type: contentType,
      price: price,
      currency: currency,
      content: content,
    ),
  );

  /// `InitiateCheckout` — the user started paying (opened the store sheet or
  /// the payment provider).
  Future<void> logInitiateCheckout({
    required double totalPrice,
    required String currency,
    String? contentId,
    String? contentType,
    int numItems = 1,
    bool paymentInfoAvailable = false,
  }) => _guard(
    'InitiateCheckout',
    () => _fb.logInitiatedCheckout(
      totalPrice: totalPrice,
      currency: currency,
      contentId: contentId,
      contentType: contentType,
      numItems: numItems,
      paymentInfoAvailable: paymentInfoAvailable,
    ),
  );

  /// `Purchase` — money actually changed hands.
  ///
  /// This is the event Meta bids against, so [value] and [currency] are
  /// required and must be the real charged amount in the real currency
  /// (ISO-4217, e.g. "USD", "UZS"). Never send a converted or estimated value.
  ///
  /// [transactionId] makes the call idempotent: the first call for a given id
  /// wins and later duplicates (resume + poll racing, a retried request) are
  /// dropped.
  Future<void> logPurchase({
    required double value,
    required String currency,
    String? transactionId,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('purchase', transactionId)) return Future<void>.value();
    return _guard(
      'Purchase',
      () => _fb.logPurchase(
        amount: value,
        currency: currency,
        parameters: _sanitize(parameters),
      ),
    );
  }

  /// `StartTrial` — a free / introductory trial began.
  ///
  /// [value] is the price the trial converts to (0 if genuinely free);
  /// Meta uses it to value the conversion.
  Future<void> logStartTrial({
    required String orderId,
    required double value,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('trial', orderId)) return Future<void>.value();
    return _guard(
      'StartTrial',
      () => _fb.logStartTrial(
        orderId: orderId,
        price: value,
        currency: currency,
        parameters: _sanitize(parameters),
      ),
    );
  }

  /// `Subscribe` — a paid subscription started (no trial).
  Future<void> logSubscribe({
    required String orderId,
    required double value,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('subscribe', orderId)) return Future<void>.value();
    return _guard(
      'Subscribe',
      () => _fb.logSubscribe(
        orderId: orderId,
        price: value,
        currency: currency,
        parameters: _sanitize(parameters),
      ),
    );
  }

  /// Escape hatch for any event without a helper above.
  Future<void> logCustomEvent(
    String name, {
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) => _guard(
    name,
    () => _fb.logEvent(
      name: name,
      parameters: _sanitize(parameters),
      valueToSum: valueToSum,
    ),
  );

  // ────────────────────────────── internals ────────────────────────────

  /// Runs [action] only when the SDK is usable, swallowing any failure.
  Future<void> _guard(String label, Future<void> Function() action) async {
    if (!_enabled) return;
    try {
      await action();
    } catch (e) {
      log('[Meta] $label failed: $e');
    }
  }

  /// `true` the first time a `(kind, id)` pair is seen. A null [id] can't be
  /// de-duplicated, so it always passes.
  bool _once(String kind, String? id) {
    if (id == null || id.isEmpty) return true;
    return _alreadyLogged.add('$kind:$id');
  }

  /// The SDK throws `ArgumentError` on any parameter value that isn't a
  /// String, num or bool. Callers shouldn't have to know that, so nulls are
  /// dropped and structured values are JSON-encoded the way Meta expects.
  Map<String, dynamic>? _sanitize(Map<String, dynamic>? parameters) {
    if (parameters == null) return null;
    final clean = <String, dynamic>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is String || value is num || value is bool) {
        clean[key] = value;
      } else if (value is Map || value is List) {
        clean[key] = jsonEncode(value);
      } else {
        clean[key] = value.toString();
      }
    });
    return clean.isEmpty ? null : clean;
  }
}
