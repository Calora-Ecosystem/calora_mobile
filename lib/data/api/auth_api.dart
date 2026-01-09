import 'package:calora/domain/model/verification/verification.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<Response> sendOtp(String email) async {
    return _dio.post('auth/send-otp/email/$email');
  }

  Future<Verification> sendOtpToPhone(String phone) async {
    final response = await _dio.post('auth/send-otp/phone/$phone');
    final data = (response.data as Map<String, dynamic>)['content'];
    return Verification.fromJson(data).copyWith(phone: phone);
  }

  Future<Response> signIn({
    String? email,
    String? phone,
    required String verificationCode,
    required String code,
    required String key,
    required String name,
    required String? fcmToken,
  }) {
    final data = {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'verificationCode': verificationCode,
      'code': code,
      'deviceInfo': {'key': key, 'name': name, 'fcmToken': fcmToken},
    };
    return _dio.post(
      '/auth/sign-in/${email == null ? 'phone' : 'email'}',
      data: data,
    );
  }
}
