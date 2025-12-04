import 'package:calora/domain/model/verification/verification.dart';

abstract class AuthRepo {
  Future<Verification> sendOtp(String email);
  Future<bool> signIn(Verification verification, String code);
}
