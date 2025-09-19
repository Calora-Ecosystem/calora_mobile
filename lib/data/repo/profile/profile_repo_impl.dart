import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ProfileRepo)
class ProfileRepoImpl extends ProfileRepo {
  @override
  Future<Profile> getProfile() {
    return Future.value(
      Profile(
        firstName: "Nurbek",
        lastName: "Nurxonov",
        birthDate: "6 Avgust 1999",
        height: 165,
        weight: 75,
        gender: "Erkak",
        goal: "Vazn yo’qotish (ozish)",
        activateStatus: "O'rtacha",
        metrics: ["km", "sm", "kg"],
      ),
    );
  }
}
