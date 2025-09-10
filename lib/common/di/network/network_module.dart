import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:calora/common/di/network/interceptor/access_token_interceptor.dart';
import 'package:calora/common/di/network/interceptor/error_interceptor.dart';
import 'package:calora/common/di/network/interceptor/language_interceptor.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(
    AliceDioAdapter aliceDioAdapter,
    BaseOptions baseOptions,
    PrettyDioLogger logger,
    ErrorInterceptor errorInterceptor,
    LanguageInterceptor languageInterceptor,
    AccessTokenInterceptor accessTokenInterceptor,
    AuthStore authStore,
  ) {
    final dio = Dio(baseOptions);

    dio.interceptors.add(languageInterceptor);
    authStore.token.call().then((token) {
      if (token != null) {
        dio.interceptors.add(accessTokenInterceptor);
      }
    });

    if (kDebugMode) {
      dio.interceptors.add(logger);
    }
    if (kProfileMode || kProfileMode) {
      dio.interceptors.add(AliceDioAdapter());
    }
    dio.interceptors.add(errorInterceptor);

    return dio;
  }

  @lazySingleton
  BaseOptions baseOptions() => BaseOptions(
    baseUrl: 'https://staging.calora.uz/api/',
    connectTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
    sendTimeout: const Duration(seconds: 120),
  );

  @lazySingleton
  PrettyDioLogger get logger => PrettyDioLogger(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    maxWidth: 90,
  );
}
