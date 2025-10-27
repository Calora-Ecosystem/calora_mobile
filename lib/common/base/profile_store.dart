import 'dart:convert';

import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'base_store.dart';

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

  Future<void> setProfile(ProfileRequest profile) async {
    await set(profile);
  }

  Future<ProfileRequest> getProfile() async {
    final profile = await call();
    return profile;
  }

  Future<void> setGender(String gender) async {
    final current = await call();
    final updated = current.copyWith(gender: gender);
    await set(updated);
  }

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
    dynamic? activityLevel,
  }) async {
    final current = await call();
    final updated = current.copyWith(
      name: name ?? current.name,
      email: email ?? current.email,
      goal: goal ?? current.goal,
      gender: gender ?? current.gender,
      height: height ?? current.height,
      weight: weight ?? current.weight,
      targetWeight: targetWeight ?? current.targetWeight,
      birthDay: birthDay ?? current.birthDay,
      bmi: bmi ?? current.bmi,
      metrics: metrics ?? current.metrics,
      activityLevel: activityLevel ?? current.activityLevel,
    );
    await set(updated);
  }
}

final profileStore = GetIt.I<ProfileStore>();

enum Gender { Male, Female }
