import 'package:calora/domain/model/verification/verification.dart';

abstract class AuthRepo {
  Future<Verification> sendOtp(String email);
  Future<Verification> sendOtpToPhone(String phone);
  Future<bool> signIn(Verification verification, String code);
}
