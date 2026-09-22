import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FacebookAnalyticsService {
  FacebookAnalyticsService._();

  static final FacebookAnalyticsService instance = FacebookAnalyticsService._();

  static const contentTypeSubscription = 'subscription';

  static const _paramSuccess = 'fb_success';

  final FacebookAppEvents _fb = FacebookAppEvents();
  final Set<String> _alreadyLogged = <String>{};

  TrackingStatus _trackingStatus = TrackingStatus.notDetermined;

  TrackingStatus get trackingStatus => _trackingStatus;

  bool get isTrackingAuthorized => _trackingStatus == TrackingStatus.authorized;

  bool get _enabled => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_enabled) return;
    try {
      await _fb.setAutoLogAppEventsEnabled(true);
      await _fb.setAdvertiserIdCollectionEnabled(!Platform.isIOS);
      if (kDebugMode) await _fb.setDebugLoggingEnabled(true);
    } catch (e) {
      log('[Meta] init failed: $e');
    }
  }

  Future<void> start() async {
    if (!_enabled) return;
    await requestTracking();
    await logActivatedApp();
  }

  Future<TrackingStatus> requestTracking() async {
    if (!_enabled || !Platform.isIOS) return TrackingStatus.notSupported;
    try {
      await _waitUntilResumed();

      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      await _applyAdvertiserTracking(status);
      return status;
    } catch (e) {
      log('[Meta] ATT request failed: $e');
      return TrackingStatus.notDetermined;
    }
  }

  Future<void> refreshTrackingStatus() async {
    if (!_enabled || !Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == _trackingStatus) return;
      await _applyAdvertiserTracking(status);
    } catch (e) {
      log('[Meta] ATT refresh failed: $e');
    }
  }

  Future<void> _applyAdvertiserTracking(TrackingStatus status) async {
    _trackingStatus = status;
    if (!Platform.isIOS) return;

    final authorized = status == TrackingStatus.authorized;
    await _guard(
      'setAdvertiserIdCollectionEnabled',
      () => _fb.setAdvertiserIdCollectionEnabled(authorized),
    );
    await _guard(
      'setAdvertiserTracking',
      // ignore: deprecated_member_use
      () => _fb.setAdvertiserTracking(enabled: authorized),
    );
  }

  Future<void> _waitUntilResumed() async {
    const step = Duration(milliseconds: 150);
    for (var i = 0; i < 20; i++) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await Future<void>.delayed(step);
        return;
      }
      await Future<void>.delayed(step);
    }
  }

  Future<void> logActivatedApp() => _guard('activateApp', _fb.activateApp);

  Future<void> setUserId(String userId) =>
      _guard('setUserID', () => _fb.setUserID(userId));

  Future<void> clearUser() => _guard('clearUser', () async {
    await _fb.clearUserID();
    await _fb.clearUserData();
  });

  Future<void> flush() => _guard('flush', _fb.flush);

  Future<void> logCompletedTutorial({
    required bool success,
    required String contentId,
  }) => _event(
    FacebookAppEvents.eventNameCompletedTutorial,
    parameters: {
      _paramSuccess: success ? 1 : 0,
      FacebookAppEvents.paramNameContentId: contentId,
    },
  );

  Future<void> logCompleteRegistration({required String method}) => _guard(
    FacebookAppEvents.eventNameCompletedRegistration,
    () => _fb.logCompletedRegistration(registrationMethod: method),
  );

  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    required String currency,
    required double valueToSum,
    Map<String, dynamic>? content,
  }) => _guard(
    FacebookAppEvents.eventNameViewedContent,
    () => _fb.logViewContent(
      id: contentId,
      type: contentType,
      currency: currency,
      price: valueToSum,
      content: content,
    ),
  );

  Future<void> logAchievedLevel({required String level}) => _event(
    FacebookAppEvents.eventNameAchievedLevel,
    parameters: {FacebookAppEvents.paramNameLevel: level},
  );

  Future<void> logSubscribe({
    required String orderId,
    required double value,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('subscribe', orderId)) return Future<void>.value();
    return _guard(
      FacebookAppEvents.eventNameSubscribe,
      () => _fb.logSubscribe(
        orderId: orderId,
        price: value,
        currency: currency,
        parameters: _sanitize(parameters),
      ),
    );
  }

  Future<void> logInitiateCheckout({
    required String contentId,
    required String contentType,
    required String currency,
    required double valueToSum,
    int numItems = 1,
    bool paymentInfoAvailable = false,
  }) => _guard(
    FacebookAppEvents.eventNameInitiatedCheckout,
    () => _fb.logInitiatedCheckout(
      totalPrice: valueToSum,
      currency: currency,
      contentId: contentId,
      contentType: contentType,
      numItems: numItems,
      paymentInfoAvailable: paymentInfoAvailable,
    ),
  );

  Future<void> logStartTrial({
    required String orderId,
    required double value,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('trial', orderId)) return Future<void>.value();
    return _guard(
      FacebookAppEvents.eventNameStartTrial,
      () => _fb.logStartTrial(
        orderId: orderId,
        price: value,
        currency: currency,
        parameters: _sanitize(parameters),
      ),
    );
  }

  Future<void> logSubmitApplication({Map<String, dynamic>? parameters}) =>
      _event(
        FacebookAppEvents.eventNameSubmitApplication,
        parameters: parameters,
      );

  Future<void> logPurchase({
    required String contentId,
    required String contentType,
    required String currency,
    required double valueToSum,
    String? transactionId,
    Map<String, dynamic>? parameters,
  }) {
    if (!_once('purchase', transactionId)) return Future<void>.value();
    return _guard(
      'fb_mobile_purchase',
      () => _fb.logPurchase(
        amount: valueToSum,
        currency: currency,
        parameters: _sanitize({
          FacebookAppEvents.paramNameContentId: contentId,
          FacebookAppEvents.paramNameContentType: contentType,
          if (transactionId != null)
            FacebookAppEvents.paramNameOrderId: transactionId,
          ...?parameters,
        }),
      ),
    );
  }

  Future<void> logAddPaymentInfo({required bool success}) => _event(
    FacebookAppEvents.eventNameAddedPaymentInfo,
    parameters: {_paramSuccess: success ? 1 : 0},
  );

  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required double price,
    required String currency,
    Map<String, dynamic>? content,
  }) => _guard(
    FacebookAppEvents.eventNameAddedToCart,
    () => _fb.logAddToCart(
      id: contentId,
      type: contentType,
      price: price,
      currency: currency,
      content: content,
    ),
  );

  Future<void> logSearch({required String searchString, String? contentType}) =>
      _guard(
        FacebookAppEvents.eventNameSearched,
        () => _fb.logSearched(
          searchString: searchString,
          contentType: contentType,
        ),
      );

  Future<void> logCustomEvent(
    String name, {
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) => _event(name, parameters: parameters, valueToSum: valueToSum);

  Future<void> _event(
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

  Future<void> _guard(String label, Future<void> Function() action) async {
    if (!_enabled) return;
    try {
      await action();
    } catch (e) {
      log('[Meta] $label failed: $e');
    }
  }

  bool _once(String kind, String? id) {
    if (id == null || id.isEmpty) return true;
    return _alreadyLogged.add('$kind:$id');
  }

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
