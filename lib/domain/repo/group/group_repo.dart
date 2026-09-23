import 'package:calora/domain/model/group/step_group.dart';

abstract class GroupRepo {
  Future<List<StepGroup>> getGroups();

  Future<StepGroup> getGroup(String id);

  Future<StepGroup> createGroup(String name);

  Future<StepGroup> joinByCode(String code);

  Future<void> deleteGroup(String id);

  Future<void> leaveGroup(String id);

  Future<void> removeMember(String groupId, int userId);
}
