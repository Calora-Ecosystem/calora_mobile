import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Response> register(String email, String name) {
    final data = {'email': email, 'questions': name};
    return _dio.post('auth/register', data: data);
  }

  Future<Response> login(String email) {
    return _dio.post('auth/send-otp/$email');
  }

  Future<Response> verify({
    required String email,
    required String verificationCode,
    required String code,
    required String key,
    required String name,
    required String? fcmToken,
  }) {
    final data = {
      'email': email,
      'verificationCode': verificationCode,
      'code': code,
      'deviceInfo': {'key': key, 'questions': name, 'fcmToken': fcmToken},
    };
    return _dio.post('auth/sign-in', data: data);
  }
}
