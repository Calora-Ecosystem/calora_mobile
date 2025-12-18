import 'package:calora/common/constants/app_configs.dart';
import 'package:calora/common/di/network/interceptor/error_interceptor.dart';
import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  @Named('refresh')
  Dio refreshDio() {
    final options = BaseOptions(
      baseUrl: kReleaseMode ? AppConfigs.baseUrl : AppConfigs.stagingBaseUrl,
      connectTimeout: const Duration(seconds: 80),
      receiveTimeout: const Duration(seconds: 80),
      sendTimeout: const Duration(seconds: 80),
    );
    final dio = Dio(options);
    dio.interceptors.clear();
    return dio;
  }

  @lazySingleton
  Dio dio(
    BaseOptions baseOptions,
    PrettyDioLogger logger,
    ErrorInterceptor errorInterceptor,
    TokenInterceptor tokenInterceptor,
    @Named('refresh') Dio refreshDio,
  ) {
    final dio = Dio(baseOptions);
    tokenInterceptor.setDio(dio, refreshDio);
    dio.interceptors.addAll([tokenInterceptor, errorInterceptor]);
    if (kDebugMode) dio.interceptors.add(logger);

    return dio;
  }

  @lazySingleton
  BaseOptions baseOptions() => BaseOptions(
    baseUrl: kReleaseMode ? AppConfigs.baseUrl : AppConfigs.stagingBaseUrl,
    connectTimeout: const Duration(seconds: 100),
    receiveTimeout: const Duration(seconds: 100),
    sendTimeout: const Duration(seconds: 100),
    headers: {'Connection': 'close', 'Content-Type': 'application/json'},
  );

  @lazySingleton
  PrettyDioLogger get logger => PrettyDioLogger(requestHeader: true, requestBody: true, maxWidth: 100);
}
