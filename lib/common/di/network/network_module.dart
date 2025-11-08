import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:calora/common/di/network/interceptor/error_interceptor.dart';
import 'package:calora/common/di/network/interceptor/language_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'interceptor/auth_interceptor.dart';
import 'interceptor/token_interceptor.dart';

@module
abstract class NetworkModule {
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

  @lazySingleton
  Dio dio(
    BaseOptions baseOptions,
    PrettyDioLogger prettyLogger,
    ErrorInterceptor errorInterceptor,
    LanguageInterceptor languageInterceptor,
    AuthInterceptor authInterceptor,
    TokenInterceptor tokenInterceptor,
    AliceDioAdapter aliceDioAdapter,
  ) {
    final dio = Dio(baseOptions);

    dio.interceptors.addAll([languageInterceptor, authInterceptor, tokenInterceptor, errorInterceptor]);

    if (kDebugMode) dio.interceptors.add(prettyLogger);
    if (kProfileMode || kReleaseMode) dio.interceptors.add(aliceDioAdapter);

    tokenInterceptor.setDio(dio);

    return dio;
  }
}
