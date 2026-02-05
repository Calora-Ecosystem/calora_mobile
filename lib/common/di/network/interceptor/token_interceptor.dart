import 'dart:async';

import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';

@lazySingleton
class TokenInterceptor extends Interceptor {
  static const String _refreshTokenEndpoint = '/auth/refresh-token';

  final AuthStore _storage;
  final CommonStore _commonStore;
  final Logger _log;

  Dio? _mainDio;
  Dio? _refreshDio;

  Completer<bool>? _refreshCompleter;

  bool _isRefreshing = false;

  TokenInterceptor(this._storage, this._log, this._commonStore);

  void setDio(Dio mainDio, Dio refreshDio) {
    _mainDio = mainDio;
    _refreshDio = refreshDio;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final language = await _commonStore.language();
      options.headers['Accept-Language'] = language?.code ?? 'UZ';
      final tokens = await _storage.token();
      final accessToken = tokens?.accessToken;
      await _commonStore.isUserPremium.set(isUserPremium(accessToken ?? ''));

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
        _log.d('Added auth to: ${options.path}');
      } else {
        _log.w('No access token for: ${options.path}');
      }

      handler.next(options);
    } catch (e, st) {
      _log.e('Error in onRequest: $e\n$st');
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;

    _log.w('Request failed: $path - Status: $statusCode');

    if (path.contains(_refreshTokenEndpoint)) {
      _log.e('Refresh endpoint itself failed - clearing tokens');
      await _clearTokens();
      return handler.next(err);
    }

    if (statusCode != 401) {
      return handler.next(err);
    }

    try {
      if (_isRefreshing) {
        _log.i('Refresh in progress, waiting...');
        final success = await _refreshCompleter?.future ?? false;

        if (success) {
          return await _retryRequest(err, handler);
        } else {
          _log.w('Refresh failed, not retrying');
          return handler.next(err);
        }
      }

      final refreshSuccess = await _performRefresh();

      if (refreshSuccess) {
        return await _retryRequest(err, handler);
      } else {
        _log.e('Token refresh failed');
        return handler.next(err);
      }
    } catch (e, st) {
      _log.e('Error handling 401: $e\n$st');
      return handler.next(err);
    }
  }

  Future<bool> _performRefresh() async {
    if (_isRefreshing) {
      _log.i('Already refreshing, waiting...');
      return await _refreshCompleter?.future ?? false;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      _log.i('═══ Starting Token Refresh ═══');

      if (_refreshDio == null) {
        _log.e('CRITICAL: refreshDio is null! Call setDio() first.');
        _refreshCompleter!.complete(false);
        return false;
      }

      final currentTokens = await _storage.token();
      final refreshToken = currentTokens?.refreshToken;
      final oldAccessToken = currentTokens?.accessToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        _log.e('No refresh token available');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      if (oldAccessToken == null || oldAccessToken.isEmpty) {
        _log.e('No access token available (required by this API)');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final refreshTokenPreview = refreshToken.length >= 10 ? refreshToken.substring(0, 10) : refreshToken;
      final accessTokenPreview = oldAccessToken.length >= 20 ? oldAccessToken.substring(0, 20) : oldAccessToken;

      _log.d('Refresh token: $refreshTokenPreview...');
      _log.d('Old access token: $accessTokenPreview...');

      final language = await _commonStore.language();
      final languageCode = language?.code ?? 'UZ';

      _log.d('Calling refresh endpoint...');
      _log.d('URL: $_refreshTokenEndpoint?rToken=$refreshToken');

      final response = await _refreshDio!.get(
        _refreshTokenEndpoint,
        queryParameters: {'rToken': refreshToken},
        options: Options(
          headers: {
            'Accept-Language': languageCode,
            'Authorization': 'Bearer $oldAccessToken',
          },
          validateStatus: (status) => status != null,
        ),
      );

      _log.i('Refresh response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        _log.e('Refresh failed with status ${response.statusCode}');
        _log.e('Response: ${response.data}');

        if (response.statusCode == 401 || response.statusCode == 403) {
          _log.e('⚠️ Refresh token is invalid or expired - CLEARING TOKENS');
          await _clearTokens();
        } else if (response.statusCode! >= 500) {
          _log.e(
            '⚠️ Server error during refresh - KEEPING TOKENS (retry later)',
          );
        } else {
          _log.e('⚠️ Client error during refresh - CLEARING TOKENS');
          await _clearTokens();
        }

        _refreshCompleter!.complete(false);
        return false;
      }

      final data = response.data;
      if (data == null) {
        _log.e('Response data is null');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      if (data is! Map<String, dynamic>) {
        _log.e('Invalid response type: ${data.runtimeType}');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      if (data['error'] != null) {
        _log.e('API error: ${data['error']}');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final content = data['content'];
      if (content == null) {
        _log.e('Content is null');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final newTokens = Token.fromJson(content as Map<String, dynamic>);

      final newAccessToken = newTokens.accessToken;
      final newRefreshToken = newTokens.refreshToken;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        _log.e('New access token is null or empty');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      if (newRefreshToken == null || newRefreshToken.isEmpty) {
        _log.e('New refresh token is null or empty');
        await _clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      await _storage.token.set(newTokens);

      final newAccessPreview = newAccessToken.length >= 20 ? newAccessToken.substring(0, 20) : newAccessToken;
      final newRefreshPreview = newRefreshToken.length >= 10 ? newRefreshToken.substring(0, 10) : newRefreshToken;

      _log.i('✅ Token refresh successful!');
      _log.d('New access token: $newAccessPreview...');
      _log.d('New refresh token: $newRefreshPreview...');

      _refreshCompleter!.complete(true);
      return true;
    } catch (e, st) {
      _log.e('Exception during refresh: $e');
      _log.e('Stack trace: $st');

      if (e is DioException) {
        _log.e('DioException type: ${e.type}');
        _log.e('Response status: ${e.response?.statusCode}');
        _log.e('Response data: ${e.response?.data}');

        final shouldClearTokens = _shouldClearTokensOnError(e);
        if (shouldClearTokens) {
          _log.w('Clearing tokens due to error type');
          await _clearTokens();
        } else {
          _log.w('Keeping tokens - error may be temporary');
        }
      } else {
        _log.w('Unknown error type - keeping tokens');
      }

      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  bool _shouldClearTokensOnError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return false;
    }
    if (statusCode == null) return false;
    if (statusCode == 401 || statusCode == 403) return true;
    if (statusCode >= 500) return false;
    if (statusCode >= 400 && statusCode < 500) return true;

    return false;
  }

  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      _log.i('Retrying request: ${err.requestOptions.path}');

      if (_mainDio == null) {
        _log.e('CRITICAL: mainDio is null!');
        return handler.next(err);
      }

      final tokens = await _storage.token();
      final accessToken = tokens?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        _log.e('No valid token for retry');
        return handler.next(err);
      }

      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _mainDio!.fetch(options);

      _log.i('✅ Retry successful');
      return handler.resolve(response);
    } catch (e, st) {
      _log.e('Retry failed: $e\n$st');
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          _log.e('⚠️ Retry failed with 403 - CLEARING TOKENS');
          await _clearTokens();
        }
      }
      return handler.next(err);
    }
  }

  Future<void> _clearTokens() async {
    _log.w('🗑️ Clearing all tokens');
    await _storage.token.set(null);
    _storage.forceLogout();
  }

  bool isUserPremium(String token) {
    try {
      if (JwtDecoder.isExpired(token)) return false;
      final Map<String, dynamic> payload = JwtDecoder.decode(token);
      final plan = (payload['plan'] as String?)?.toLowerCase() ?? 'free';
      return plan == 'premium';
    } catch (e) {
      return false;
    }
  }
}
