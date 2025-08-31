import 'package:calora/domain/model/verification/verification.dart';

abstract class AuthRepo {
  Future<Verification> register(String email, String name);

  Future<Verification> login(String email);

  Future<void> verify(Verification verification, String code);
}
