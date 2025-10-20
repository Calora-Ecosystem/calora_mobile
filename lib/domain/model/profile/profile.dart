import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  factory Profile({
    String? firstName,
    String? lastName,
    String? birthDate,
    double? height,
    double? weight,
    String? gender,
    String? goal,
    String? activateStatus,
    List<String>? metrics,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

enum Gender { Male, Female }
