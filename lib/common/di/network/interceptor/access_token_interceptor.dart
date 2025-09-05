import 'package:calora/data/store/auth/auth_store.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AccessTokenInterceptor extends Interceptor {
  AuthStore authStore;

  AccessTokenInterceptor(this.authStore);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final result = await authStore.token.call();
    options.headers['Access-Token'] = result?.accessToken ?? "";
    handler.next(options);
  }
}
