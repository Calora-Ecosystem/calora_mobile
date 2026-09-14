import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Reports [DioException]s to Sentry with a **scrubbed**, **filtered** and
/// **grouped** payload, for production network-failure debugging.
///
///  * Secrets & PII (auth headers, tokens, passwords, OTP codes, emails,
///    phones, names, …) are redacted from headers, query, request body and
///    response body before anything leaves the device — see [_isSensitiveKey].
///  * Pure connectivity noise (timeouts, no-internet, cancellations) is
///    dropped so it doesn't burn the Sentry quota — see [_shouldCapture].
///  * Similar failures share a [Scope.fingerprint] (method + normalised path +
///    status) so they roll up into a single Sentry issue instead of thousands.
///
/// The captured throwable is a purpose-built [DioNetworkException] with a clean,
/// controlled message, so no unscrubbed URL/body can leak through the
/// exception value; every detail lives in the redacted `request` / `response`
/// contexts instead.
class DioSentryReporter {
  const DioSentryReporter._();

  static const _redacted = '[REDACTED]';
  static const _maxStringLength = 1000;
  static const _maxCollectionLength = 50;
  static const _maxDepth = 6;

  /// Keys redacted by exact (normalised) match. These would over-match as
  /// substrings (e.g. `code` inside `countryCode`), so they're matched whole.
  static const _sensitiveExactKeys = <String>{
    'email',
    'phone',
    'phonenumber',
    'code',
    'verificationcode',
    'name',
    'firstname',
    'lastname',
    'fullname',
    'birthdate',
    'birthday',
    'dob',
    'address',
    'ssn',
    'passport',
    'latitude',
    'longitude',
    'lat',
    'lng',
  };

  /// Keys redacted by substring (normalised) match — unambiguous secrets.
  static const _sensitiveSubstrings = <String>[
    'authorization',
    'password',
    'passwd',
    'pwd',
    'secret',
    'token',
    'apikey',
    'credential',
    'ssotoken',
    'fcmtoken',
    'rtoken',
    'otp',
    'cookie',
    'session',
    'cvv',
    'cardnumber',
  ];

  /// Fire-and-forget report. Never throws — telemetry must not break the
  /// request/error flow.
  static void report(DioException err) {
    // Don't ship local-development network errors to Sentry; only profile /
    // release builds report, so dev noise doesn't burn the quota.
    if (kDebugMode) return;

    try {
      if (!_shouldCapture(err)) return;

      final request = err.requestOptions;
      final response = err.response;
      final statusCode = response?.statusCode;
      final method = request.method.toUpperCase();
      final path = request.uri.path; // path only — never the query string

      final throwable = DioNetworkException(
        method: method,
        path: path,
        statusCode: statusCode,
        type: err.type.name,
      );

      unawaited(
        Sentry.captureException(
          throwable,
          stackTrace: err.stackTrace,
          withScope: (scope) async {
            // 5xx / transport-level → error; 4xx → warning.
            scope.level = (statusCode == null || statusCode >= 500)
                ? SentryLevel.error
                : SentryLevel.warning;

            // Group by endpoint shape + status: `/food/1` and `/food/2`, across
            // every user, collapse into one issue.
            scope.fingerprint = [
              'dio',
              method,
              _normalisePath(path),
              '${statusCode ?? err.type.name}',
            ];

            await scope.setTag('http.method', method);
            await scope.setTag('dio.error_type', err.type.name);
            if (statusCode != null) {
              await scope.setTag('http.status_code', '$statusCode');
            }

            await scope.setContexts('request', {
              'method': method,
              'url': path,
              'query': _scrub(request.queryParameters),
              'headers': _scrub(request.headers),
              'body': _describeBody(request.data),
            });

            if (response != null) {
              await scope.setContexts('response', {
                'status_code': statusCode,
                'data': _scrub(response.data),
              });
            }
          },
        ),
      );
    } catch (_) {
      // Swallow: a reporting failure must never interfere with error handling.
    }
  }

  /// Drops connectivity noise (timeouts, no-internet, cancellations) so it
  /// doesn't spam Sentry; keeps real server/unexpected failures.
  static bool _shouldCapture(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
        return false;
      case DioExceptionType.unknown:
        return err.error is! SocketException &&
            err.error is! HttpException &&
            err.error is! TlsException;
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
        return true;
    }
  }

  /// Collapses id-like path segments so fingerprints stay stable:
  /// `/food/123` → `/food/{id}`, `/users/9af3b2…` → `/users/{id}`.
  static String _normalisePath(String path) {
    return path
        .split('/')
        .map((seg) {
          if (seg.isEmpty) return seg;
          if (RegExp(r'^\d+$').hasMatch(seg)) return '{id}';
          if (RegExp(r'^[0-9a-fA-F-]{8,}$').hasMatch(seg)) return '{id}';
          return seg;
        })
        .join('/');
  }

  static dynamic _describeBody(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'type': 'multipart/form-data',
        'fields': {
          for (final f in data.fields)
            f.key: _isSensitiveKey(f.key) ? _redacted : _truncate(f.value),
        },
        // File names only — never the bytes.
        'files': data.files.map((f) => f.key).toList(),
      };
    }
    if (data is String) {
      // Body is often a JSON string; decode so we can redact by key.
      try {
        return _scrub(jsonDecode(data));
      } catch (_) {
        return _truncate(data);
      }
    }
    return _scrub(data);
  }

  static dynamic _scrub(dynamic value, [int depth = 0]) {
    if (depth > _maxDepth) return '…';
    if (value is Map) {
      final out = <String, dynamic>{};
      var i = 0;
      for (final entry in value.entries) {
        if (i++ >= _maxCollectionLength) {
          out['…'] = 'truncated (${value.length} keys)';
          break;
        }
        final key = entry.key.toString();
        out[key] = _isSensitiveKey(key)
            ? _redacted
            : _scrub(entry.value, depth + 1);
      }
      return out;
    }
    if (value is Iterable) {
      return value
          .take(_maxCollectionLength)
          .map((e) => _scrub(e, depth + 1))
          .toList();
    }
    if (value is String) return _truncate(value);
    if (value is num || value is bool || value == null) return value;
    return _truncate(value.toString());
  }

  static bool _isSensitiveKey(String key) {
    final normalised = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    if (_sensitiveExactKeys.contains(normalised)) return true;
    return _sensitiveSubstrings.any(normalised.contains);
  }

  static String _truncate(String value) => value.length > _maxStringLength
      ? '${value.substring(0, _maxStringLength)}… (${value.length} chars)'
      : value;
}

/// Clean, controlled throwable captured in place of the raw [DioException], so
/// the Sentry issue title/value can't leak an unscrubbed URL or body. All
/// detail is attached via redacted scope contexts.
class DioNetworkException implements Exception {
  DioNetworkException({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.type,
  });

  final String method;
  final String path;
  final int? statusCode;
  final String type;

  @override
  String toString() =>
      'DioNetworkException: $method $path → ${statusCode ?? type}';
}
