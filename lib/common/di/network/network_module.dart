import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:calora/common/di/network/error_interceptor.dart';
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
  ) {
    final dio = Dio(baseOptions);

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
