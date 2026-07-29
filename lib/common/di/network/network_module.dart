import 'dart:io';
import 'package:calora/common/constants/app_configs.dart';
import 'package:calora/common/di/network/interceptor/error_interceptor.dart';
import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  @Named('country')
  Dio countryDio() {
    // Short timeouts on purpose: this Dio backs the auth-page country
    // check. If the geo service is blocked or slow, the user should fall
    // through to the fallback provider / other detection signals within
    // seconds — not stare at a spinner for 50 s.
    final options = BaseOptions(
      baseUrl: 'https://api.country.is/',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    );
    final dio = Dio(options);
    // _allowBadCertificates(dio);
    dio.interceptors.clear();
    return dio;
  }

  @lazySingleton
  @Named('refresh')
  Dio refreshDio() {
    String baseUrl = kReleaseMode ? AppConfigs.baseUrl : AppConfigs.stagingBaseUrl;
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      sendTimeout: const Duration(seconds: 50),
    );
    final dio = Dio(options);
    // _allowBadCertificates(dio);
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
    // _allowBadCertificates(dio);
    tokenInterceptor.setDio(dio, refreshDio);
    dio.interceptors.addAll([tokenInterceptor, errorInterceptor]);
    if (kDebugMode) dio.interceptors.add(logger);

    return dio;
  }

  @lazySingleton
  BaseOptions baseOptions() {
    String baseUrl = kReleaseMode ? AppConfigs.baseUrl : AppConfigs.stagingBaseUrl;
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      sendTimeout: const Duration(seconds: 50),
      headers: {'Connection': 'close', 'Content-Type': 'application/json'},
    );
  }

  @lazySingleton
  PrettyDioLogger get logger =>
      PrettyDioLogger(requestHeader: true, requestBody: true, maxWidth: 100);

  // void _allowBadCertificates(Dio dio) {
  //   if (kDebugMode && !kIsWeb) {
  //     (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  //       final client = HttpClient();
  //       client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  //       return client;
  //     };
  //   }
  // }
}
