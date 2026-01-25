import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/enums/connectivity_quality_enum.dart';
import 'package:calora/presentation/app/connectivity/management/connectivity_management.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class ConnectivityManager
    extends Manager<ConnectivityState, ConnectivityEffect> {
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final HttpClient _httpClient;
  Timer? _debounce;
  Timer? _retryTimer;

  int _requestId = 0;
  int _consecutiveFailures = 0;
  bool _isCheckingConnection = false;
  bool _hasShownOverlay = false;

  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 50);

  ConnectivityManager(this._connectivity) : super(ConnectivityState.initial()) {
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 10);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    _hasShownOverlay = false;

    Future.delayed(const Duration(milliseconds: 1000), _checkConnection);
  }

  Future<void> _checkConnection() async {
    if (_isCheckingConnection) {
      log('[_checkConnection] Already checking connection, skipping...');
      return;
    }

    _isCheckingConnection = true;
    final currentRequest = ++_requestId;
    log('[_checkConnection] Starting check #$currentRequest');

    try {
      if (currentRequest > 1) {
        emit(state.copyWith(isLoading: true, isSuccess: false, isError: false));
      }

      final results = await _connectivity.checkConnectivity();

      if (currentRequest != _requestId) {
        log('[_checkConnection] Request #$currentRequest outdated, aborting');
        return;
      }

      final hasInterface = _hasNetworkInterface(results);
      log('[_checkConnection] hasInterface=$hasInterface, results=$results');

      final hasInternet = hasInterface
          ? await _hasInternetConnectivity(currentRequest)
          : false;

      if (currentRequest != _requestId) {
        log(
          '[_checkConnection] Request #$currentRequest outdated after internet check',
        );
        return;
      }

      log('[_checkConnection] hasInternet=$hasInternet');

      if (hasInternet) {
        _handleConnectionSuccess(results);
      } else {
        _handleConnectionFailure(results, hasInterface: hasInterface);
      }
    } catch (e, stackTrace) {
      log(
        '[_checkConnection] Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      if (currentRequest == _requestId) {
        _handleConnectionFailure([], hasInterface: false);
      }
    } finally {
      _isCheckingConnection = false;
    }
  }

  void _handleConnectionSuccess(List<ConnectivityResult> results) {
    log('[_handleConnectionSuccess] Connection restored');

    final wasDisconnected = !state.isConnected;

    _consecutiveFailures = 0;
    _retryTimer?.cancel();

    emit(
      state.copyWith(
        isLoading: false,
        isSuccess: true,
        isError: false,
        isConnected: true,
        hasInterface: true,
        results: results,
        connectionQuality: _determineConnectionQuality(results),
        lastCheckedAt: DateTime.now(),
      ),
    );

    if (wasDisconnected && _hasShownOverlay) {
      log('[_handleConnectionSuccess] Removing overlay (was disconnected)');
      _hasShownOverlay = false;
      publish(const ConnectivityEffect.removeOverlay());
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    log('[_onConnectivityChanged] New results: $results');

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      log('[_onConnectivityChanged] Debounce complete, triggering check');
      _checkConnection();
    });
  }

  void _handleConnectionFailure(
    List<ConnectivityResult> results, {
    required bool hasInterface,
  }) {
    _consecutiveFailures++;
    log(
      '[_handleConnectionFailure] Failure #$_consecutiveFailures, hasInterface=$hasInterface, _hasShownOverlay=$_hasShownOverlay',
    );

    final wasConnected = state.isConnected;

    emit(
      state.copyWith(
        isLoading: false,
        isSuccess: false,
        isError: true,
        isConnected: false,
        hasInterface: hasInterface,
        results: results,
        connectionQuality: ConnectionQuality.none,
        lastCheckedAt: DateTime.now(),
      ),
    );

    if (wasConnected && !_hasShownOverlay) {
      log('[_handleConnectionFailure] Showing overlay (just lost connection)');
      _hasShownOverlay = true;
      publish(const ConnectivityEffect.showOverlay());
    } else if (_consecutiveFailures == 1 && !_hasShownOverlay) {
      log(
        '[_handleConnectionFailure] Showing overlay (first check, no connection)',
      );
      _hasShownOverlay = true;
      publish(const ConnectivityEffect.showOverlay());
    } else {
      log(
        '[_handleConnectionFailure] NOT showing overlay: wasConnected=$wasConnected, _consecutiveFailures=$_consecutiveFailures, _hasShownOverlay=$_hasShownOverlay',
      );
    }

    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_consecutiveFailures >= _maxRetries) {
      log(
        '[_scheduleRetry] Max retries ($_maxRetries) reached, stopping automatic retries',
      );
      return;
    }

    _retryTimer?.cancel();

    final exponent = (_consecutiveFailures - 1).clamp(0, 5);
    final delayMs = _baseRetryDelay.inMilliseconds * (1 << exponent);
    final delay = Duration(
      milliseconds: delayMs.clamp(0, _maxRetryDelay.inMilliseconds),
    );

    log(
      '[_scheduleRetry] Scheduling retry #$_consecutiveFailures in ${delay.inSeconds}s',
    );
    _retryTimer = Timer(delay, _checkConnection);
  }

  Future<bool> _hasInternetConnectivity(int requestId) async {
    final checks = [
      _headRequest(Uri.parse('https://www.gstatic.com/generate_204')),
      _headRequest(Uri.parse('https://www.google.com/generate_204')),
    ];

    try {
      final firstSuccess = await Future.any(
        checks,
      ).timeout(const Duration(seconds: 6));

      if (requestId != _requestId) {
        log('[_hasInternetConnectivity] Request #$requestId outdated');
        return state.isConnected;
      }

      return firstSuccess;
    } on TimeoutException {
      log('[_hasInternetConnectivity] All checks timed out');
      return false;
    } catch (e) {
      log('[_hasInternetConnectivity] All checks failed: $e');
      return false;
    }
  }

  Future<bool> _headRequest(Uri uri) async {
    try {
      final req = await _httpClient.headUrl(uri);
      req.headers.set('Connection', 'close');
      final res = await req.close();

      await res.drain();

      final isSuccess = res.statusCode >= 200 && res.statusCode < 300;
      log(
        '[_headRequest] Check to $uri: ${isSuccess ? "SUCCESS" : "FAILED"} (${res.statusCode})',
      );
      return isSuccess;
    } catch (e) {
      log('[_headRequest] Check to $uri failed', error: e);
      throw Exception('HEAD request failed: $e');
    }
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
  }

  ConnectionQuality _determineConnectionQuality(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionQuality.excellent;
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionQuality.good;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionQuality.fair;
    }
    return ConnectionQuality.poor;
  }

  void retry() {
    log('[retry] Manual retry triggered by user');
    _consecutiveFailures = 0;
    _retryTimer?.cancel();
    _debounce?.cancel();
    _checkConnection();
  }

  @override
  Future<void> close() {
    log('[close] Cleaning up ConnectivityManager');
    _subscription.cancel();
    _debounce?.cancel();
    _retryTimer?.cancel();
    _httpClient.close(force: true);
    return super.close();
  }
}
