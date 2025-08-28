import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

@freezed
abstract class Verification with _$Verification {
  const factory Verification({
    String? verificationCode,
    DateTime? expireDate,
    String? email,
  }) = _Verification;

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);
}
