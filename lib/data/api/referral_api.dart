import 'package:calora/domain/model/referral/referral_info.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ReferralApi {
  final Dio _dio;

  ReferralApi(this._dio);

  Future<ReferralInfo> getMy() async {
    final response = await _dio.get<Map<String, dynamic>>('referrals/me');
    return ReferralInfo.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }

  /// A fresh invite code for this share — every earlier code keeps working.
  Future<String> newCode() async {
    final response = await _dio.post<Map<String, dynamic>>('referrals/code');
    return response.data!['content'] as String;
  }

  Future<List<ReferredFriend>> getInvited({
    int skip = 0,
    int take = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'referrals/invited',
      queryParameters: {'Skip': skip, 'Take': take},
    );
    final content = response.data!['content'] as List<dynamic>? ?? [];
    return content
        .whereType<Map<String, dynamic>>()
        .map(ReferredFriend.fromJson)
        .toList();
  }

  /// Confirms that the user signed up through a friend's [code].
  Future<ApplyReferralResult> apply(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'referrals/apply',
      data: {'code': code},
    );
    return ApplyReferralResult.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }
}
