import 'package:dio/dio.dart';

/// Reads the backend's error code (the `error` field of the response
/// wrapper, e.g. `insufficient_coins`) from a failed request.
extension ApiErrorExtension on Object {
  String? get apiErrorCode {
    final self = this;
    if (self is! DioException) return null;
    final data = self.response?.data;
    if (data is Map) return data['error']?.toString();
    return null;
  }
}
