import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stat.freezed.dart';
part 'user_stat.g.dart';

@freezed
abstract class UserStatRequest with _$UserStatRequest {
  const factory UserStatRequest({
    required String firstName,
    required String lastName,
    required int stepCount,
    required int talks,
    @Default(false) bool isMe,
    @Default(false) bool isWinner,
  }) = _UserStatRequest;

  factory UserStatRequest.fromJson(Map<String, dynamic> json) => _$UserStatRequestFromJson(json);
}

extension UserStatExtension on UserStatRequest {
  String getInitials() {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName[0];
    if (lastName.isEmpty) return firstName[0];
    return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
  }

  String get prettySteps => stepCount.toPrettyFormat();

  String get prettyTalks => talks.toPrettyFormat();
}
