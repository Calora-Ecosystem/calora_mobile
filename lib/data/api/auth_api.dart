import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Response> sendOtp(String email) {
    return _dio.post('auth/send-otp/email/$email');
  }

  Future<Response> signIn({
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
      'deviceInfo': {'key': key, 'name': name, 'fcmToken': fcmToken},
    };
    return _dio.post('auth/sign-in/email', data: data);
  }
}
