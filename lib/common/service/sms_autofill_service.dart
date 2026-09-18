import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:smart_auth/smart_auth.dart';

/// Android SMS code autofill (Google's SMS User Consent API).
///
/// The API only reports messages that arrive *after* the listener is armed, so
/// [start] has to run before the `send-otp` request is fired, not when the
/// verification screen opens. A code that lands before anyone is listening is
/// buffered so the screen can still pick it up via [takeBufferedCode].
///
/// iOS has no equivalent: the system fills `oneTimeCode` fields from the
/// QuickType bar on its own, so every method here is a no-op there.
class SmsAutofillService {
  SmsAutofillService._();

  static final SmsAutofillService instance = SmsAutofillService._();

  static const int codeLength = 6;
  static const String _codeMatcher = r'\d{6}';

  final StreamController<String> _codes = StreamController<String>.broadcast();

  String? _bufferedCode;
  bool _listening = false;
  int _session = 0;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Stream<String> get codes => _codes.stream;

  String? takeBufferedCode() {
    final code = _bufferedCode;
    _bufferedCode = null;
    return code;
  }

  Future<void> start() async {
    if (!_supported || _listening) return;

    final session = ++_session;
    _listening = true;
    _bufferedCode = null;

    final result = await SmartAuth.instance.getSmsWithUserConsentApi(
      matcher: _codeMatcher,
    );

    if (session != _session) return;
    _listening = false;

    final code = result.data?.code;
    if (code == null || code.length != codeLength) {
      log(
        'SmsAutofillService: no usable code (${result.error ?? (result.isCanceled ? 'canceled by user' : 'no match')})',
      );
      return;
    }

    if (_codes.hasListener) {
      _codes.add(code);
    } else {
      _bufferedCode = code;
    }
  }

  Future<void> stop() async {
    if (!_supported || !_listening) return;

    _session++;
    _listening = false;
    _bufferedCode = null;

    await SmartAuth.instance.removeUserConsentApiListener();
  }
}
