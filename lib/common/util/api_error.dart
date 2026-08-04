import 'package:calora/common/gen/strings.dart';
import 'package:dio/dio.dart';

/// Extracts a human-readable message from an error thrown by the API layer
/// (typically a [DioException]) so it can be shown to the user.
///
/// Understands the two error body shapes the backend returns:
///   * `{ "error": "..." }` — a plain message string
///   * `{ "modelStateError": [ { "errorMessage": "..." }, ... ] }` — validation
///
/// Falls back to [fallback] (a generic localized string by default) whenever
/// the backend didn't provide a usable message, or the failure was a network /
/// timeout error with no response body — so the user never sees a raw
/// `DioException [...]` dump.
String apiErrorMessage(Object? error, {String? fallback}) {
  final generic = fallback ?? Strings.somethingWentWrong;

  if (error is DioException) {
    final fromBody = _messageFromBody(error.response?.data);
    if (fromBody != null) return fromBody;
  }

  return generic;
}

/// Pulls the first usable message out of a decoded error body. Returns `null`
/// when nothing readable is present so the caller can fall back.
String? _messageFromBody(dynamic data) {
  // Some endpoints return a bare string body.
  if (data is String) {
    final trimmed = data.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  if (data is! Map) return null;

  // Shape: { "modelStateError": [ { "errorMessage": "..." } ] }
  final modelStateError = data['modelStateError'];
  if (modelStateError is List && modelStateError.isNotEmpty) {
    final first = modelStateError.first;
    if (first is Map) {
      final message = first['errorMessage'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
  }

  // Shape: { "error": "..." } (string, or a nested { "message": "..." })
  final error = data['error'];
  if (error is String && error.trim().isNotEmpty) return error.trim();
  if (error is Map) {
    final message = error['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }

  // Shape: { "message": "..." }
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) return message.trim();

  return null;
}
