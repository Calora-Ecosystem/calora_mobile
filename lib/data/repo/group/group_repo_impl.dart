import 'package:calora/data/api/groups_api.dart';
import 'package:calora/domain/model/group/step_group.dart';
import 'package:calora/domain/repo/group/group_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: GroupRepo)
class GroupRepoImpl implements GroupRepo {
  final GroupsApi _api;

  GroupRepoImpl(this._api);

  @override
  Future<List<StepGroup>> getGroups() => _api.getGroups();

  @override
  Future<StepGroup> getGroup(String id) => _api.getGroup(id);

  @override
  Future<StepGroup> createGroup(String name) => _api.createGroup(name);

  @override
  Future<StepGroup> joinByCode(String code) => _api.joinByCode(code);

  @override
  Future<void> deleteGroup(String id) => _api.deleteGroup(id);

  @override
  Future<void> leaveGroup(String id) => _api.leaveGroup(id);

  @override
  Future<void> removeMember(String groupId, int userId) =>
      _api.removeMember(groupId, userId);
}
