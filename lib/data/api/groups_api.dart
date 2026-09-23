import 'package:calora/domain/model/group/step_group.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GroupsApi {
  final Dio _dio;

  GroupsApi(this._dio);

  Future<List<StepGroup>> getGroups() async {
    final response = await _dio.get<Map<String, dynamic>>('step-groups');
    final content = response.data!['content'] as List<dynamic>? ?? [];
    return content
        .whereType<Map<String, dynamic>>()
        .map(StepGroup.fromJson)
        .toList();
  }

  Future<StepGroup> getGroup(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('step-groups/$id');
    return StepGroup.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }

  Future<StepGroup> createGroup(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'step-groups',
      data: {'name': name},
    );
    return StepGroup.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }

  Future<StepGroup> joinByCode(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'step-groups/join',
      data: {'code': code},
    );
    return StepGroup.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteGroup(String id) => _dio.delete('step-groups/$id');

  Future<void> leaveGroup(String id) =>
      _dio.post<Map<String, dynamic>>('step-groups/$id/leave');

  Future<void> removeMember(String groupId, int userId) =>
      _dio.delete('step-groups/$groupId/members/$userId');
}
