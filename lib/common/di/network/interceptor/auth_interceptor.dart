import 'package:calora/data/store/auth/auth_store.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@singleton
class AuthInterceptor extends Interceptor {
  final AuthStore _storage;
  final Logger _log;

  AuthInterceptor(this._storage, this._log);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final tokens = await _storage.token();
      final access = tokens?.accessToken;
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    } catch (e, st) {
      _log.e('Auth interceptor error\n$e\n$st');
      handler.reject(DioException(requestOptions: options, error: e), true);
    }
  }
}
