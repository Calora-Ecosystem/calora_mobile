import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  @override
  Future<List<UserStat>> fetchUserStates() {
    return Future.value(_userStates);
  }

  List<UserStat> _userStates = [
    UserStat(
      firstName: "Lolaxon",
      lastName: "Ahmedov",
      talks: 159,
      stepCount: 104943,
    ),
    UserStat(
      firstName: "Nurbek",
      lastName: "Nurxonov",
      talks: 155,
      stepCount: 69030,
    ),
    UserStat(
      firstName: "Akhmadjon",
      lastName: "Boydadayev",
      talks: 149,
      stepCount: 66934,
    ),
    UserStat(
      firstName: "Sardor",
      lastName: "Eshniyoz",
      talks: 140,
      stepCount: 59030,
    ),
    UserStat(
      firstName: "Sherzod",
      lastName: "Bekniyozov",
      talks: 129,
      stepCount: 53030,
    ),
    UserStat(
      firstName: "Jasur",
      lastName: "Eshonqulov",
      talks: 121,
      stepCount: 52943,
    ),
    UserStat(
      firstName: "Abror",
      lastName: "Sodiqov",
      talks: 119,
      stepCount: 52430,
      isMe: true,
    ),
    UserStat(
      firstName: "Abdurashid",
      lastName: "Abdurasulov",
      talks: 119,
      stepCount: 1046,
    ),
  ];
}
