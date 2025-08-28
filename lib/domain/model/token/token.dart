import 'package:freezed_annotation/freezed_annotation.dart';

part 'token.freezed.dart';
part 'token.g.dart';

@freezed
abstract class Token with _$Token {
  const factory Token({
    String? accessToken,
    String? refreshToken,
    DateTime? refreshTokenExpireAt,
  }) = _Token;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
}
