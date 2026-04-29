import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ProfileStore extends BaseStore<ProfileRequest> {
  ProfileStore()
    : super(
        'user_profile',
        serialize: (value) => jsonEncode(value.toJson()),
        deserialize: (value) {
          if (value == null || value.isEmpty) return const ProfileRequest();
          try {
            final Map<String, dynamic> map = jsonDecode(value);
            return ProfileRequest.fromJson(map);
          } catch (_) {
            return const ProfileRequest();
          }
        },
      );

  Stream<ProfileRequest> stream() async* {
    yield await call();

    yield* watch();
  }

  Future<void> setProfile(ProfileRequest profile) async {
    await set(profile);
  }

  Future<ProfileRequest> getProfile() async {
    final profile = await call();
    return profile;
  }

  Future<int?> getUserId() async {
    final profile = await call();
    return profile.userId;
  }

  Future<void> setGender(String gender) async {
    final current = await call();
    final updated = current.copyWith(gender: gender);
    await set(updated);
  }

  Future<void> updateActivityLevel(String level) async {
    final current = await call();
    final updated = current.copyWith(activityLevel: level);
    await set(updated);
  }

  Future<void> delete() async => await clear();

  Future<void> updateProfile({
    String? name,
    String? email,
    String? goal,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? birthDay,
    double? bmi,
    String? metrics,
    int? userId,
    String? physicalActivity,
    String? activityLevel,
    String? language,
  }) async {
    final current = await call();
    final updated = current.copyWith(
      userId: userId ?? current.userId,
      name: name ?? current.name,
      email: email ?? current.email,
      goal: goal ?? current.goal,
      gender: gender ?? current.gender,
      height: height ?? current.height,
      weight: weight ?? current.weight,
      targetWeight: targetWeight ?? current.targetWeight,
      birthDay: birthDay ?? current.birthDay,
      bmi: bmi ?? current.bmi,
      activityLevel: activityLevel ?? current.activityLevel,
      physicalActivity: physicalActivity ?? current.physicalActivity,
      language: language ?? current.language,
    );
    await set(updated);
  }
}

final profileStore = GetIt.I<ProfileStore>();

enum Gender {
  Male,
  Female,
  Unknown;

  bool get isMale => this == Gender.Male;

  bool get isFemale => this == Gender.Female;

  bool get isUnknown => this == Gender.Unknown;

  String get displayName {
    switch (this) {
      case Gender.Male:
        return Strings.male;
      case Gender.Female:
        return Strings.female;
      case Gender.Unknown:
        return 'Unknown';
    }
  }

  String toApi() {
    switch (this) {
      case Gender.Male:
        return 'Male';
      case Gender.Female:
        return 'Female';
      case Gender.Unknown:
        return 'Unknown';
    }
  }

  static Gender fromApi(String? value) {
    switch (value) {
      case 'Male':
        return Gender.Male;
      case 'Female':
        return Gender.Female;
      default:
        return Gender.Unknown;
    }
  }

  static Gender fromDisplayName(String? value) {
    if (value == Strings.male) return Gender.Male;
    if (value == Strings.female) return Gender.Female;
    return Gender.Unknown;
  }
}
