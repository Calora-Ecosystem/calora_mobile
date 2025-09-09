import 'package:calora/domain/model/user/user_stat.dart';

abstract class StepRepo {
  Future<List<UserStat>> fetchUserStates();
}
