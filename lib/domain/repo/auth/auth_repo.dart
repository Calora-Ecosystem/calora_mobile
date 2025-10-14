import 'package:calora/domain/model/verification/verification.dart';

abstract class AuthRepo {
  Future<Verification> sendOtp(String email);
  Future<void> signIn(Verification verification, String code);
  Future<bool> checkExtras(); // 3-qadam
  Future<void> saveExtras(Map<String, dynamic> extras); // 4-qadam
  Future<void> fetchUser(); // 5-qadam
}
