import 'package:calora/domain/model/profile/profile.dart';

abstract class ProfileRepo {
  Future<Profile> getProfile();
}
