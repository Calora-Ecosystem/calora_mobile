// lib/domain/mapper/profile/profile_mapper.dart
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

extension ProfileRequestMapper on ProfileRequest {
  Profile toProfile() {
    return Profile(
      firstName: name,
      lastName: null,
      birthDate: birthDay,
      height: height,
      weight: weight,
      gender: gender,
      goal: goal,
      activateStatus: activityLevel?.toString(),
      metrics: metrics?.split('/'),
    );
  }
}

extension ProfileToRequest on Profile {
  ProfileRequest toProfileRequest() {
    return ProfileRequest(
      name: firstName,
      birthDay: birthDate,
      height: height,
      weight: weight,
      gender: gender,
      goal: goal,
      activityLevel: activateStatus,
      metrics: metrics?.join('/'),
    );
  }
}
