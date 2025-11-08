import 'dart:async';
import 'dart:math';

import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';

@lazySingleton
class TokenInterceptor extends QueuedInterceptor {
  static const int _maxRetries = 3;
  static const int _baseDelayMs = 150;
  static const String _refreshTokenEndpoint = '/auth/refresh-token';

  final AuthStore _storage;
  final Logger _log;

  Dio? _dio;
  Completer<String?>? _refreshCompleter;
  bool _refreshFailed = false;

  TokenInterceptor(this._storage, this._log);

  bool get refreshFailed => _refreshFailed;

  void setDio(Dio dio) {
    _dio = dio;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.path.contains(_refreshTokenEndpoint)) {
      _log.w('Refresh token request failed, clearing tokens.');
      await _clearTokens();
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_refreshFailed) {
      final refresh = await _storage.refreshToken.call();

      if (refresh == null || JwtDecoder.isExpired(refresh)) {
        _log.w('Refresh token expired or missing.');
        await _clearTokens();
        return handler.next(err);
      }

      try {
        final newAccess = await _refreshToken(refresh);

        if (newAccess != null && _dio != null) {
          _log.i('Token refreshed, retrying original request.');

          final request = err.requestOptions;
          request.headers['Authorization'] = 'Bearer $newAccess';

          final options = Options(
            method: request.method,
            headers: request.headers,
            contentType: request.contentType,
            responseType: request.responseType,
          );

          try {
            final response = await _dio!.request(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: options,
            );
            return handler.resolve(response);
          } catch (e, st) {
            _log.e('Retry request failed\n$e\n$st');
            return handler.next(err);
          }
        } else {
          _log.e('Refresh failed, clearing tokens.');
          await _clearTokens();
        }
      } catch (e, st) {
        _log.e('Error while retrying after refresh\n$e\n$st');
        await _clearTokens();
      }
    }

    handler.next(err);
  }

  Future<String?> _refreshToken(String refresh) async {
    if (_refreshCompleter != null) {
      _log.i('Waiting for ongoing refresh...');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          _log.i('Refreshing token (attempt $attempt)...');

          final refreshDio = Dio(
            BaseOptions(
              baseUrl: 'https://staging.calora.uz/api/',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          final response = await refreshDio.get(_refreshTokenEndpoint, queryParameters: {'rToken': refresh});

          if (response.statusCode == 200 && response.data != null) {
            final tokens = Token.fromJson(response.data['content']);
            await _storage.token.set(tokens);

            _log.i('Token refreshed successfully.');
            _refreshCompleter!.complete(tokens.accessToken);
            _refreshFailed = false;

            return tokens.accessToken;
          } else {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              message: 'Invalid refresh response',
            );
          }
        } catch (e, st) {
          _log.w('Refresh attempt $attempt failed\n$e\n$st');

          if (attempt == _maxRetries) {
            _refreshFailed = true;
            _refreshCompleter!.complete(null);
            await _clearTokens();
            return null;
          }

          final backoff = pow(2, attempt) * _baseDelayMs + Random().nextInt(_baseDelayMs);
          await Future.delayed(Duration(milliseconds: backoff.toInt()));
        }
      }
    } finally {
      _refreshCompleter = null;
    }

    return null;
  }

  Future<void> _clearTokens() async {
    _refreshFailed = true;
    await _storage.token.set(const Token());
    await _storage.refreshToken.set(null);
  }
}
