import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/mapper/detail/detail_mapper.dart';
import 'package:calora/domain/mapper/detail/profile_mapper.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ProfileRepo)
class ProfileRepoImpl extends ProfileRepo {
  final ProfileApi _api;

  ProfileRepoImpl(this._api);

  @override
  Future<ProfileRequest> getProfile() async {
    final meResponse = await _api.getProfileMe();
    final extrasResponse = await _api.getProfileExtras();
    final targetWeight = await _api.getTargetWeight();

    final meData = meResponse.data['content'];
    final extrasData = extrasResponse.data['content'];
    final target = targetWeight.data['content'][0];
    final profile = ProfileRequest.fromJson(extrasData);
    final updated = profile.copyWith(
      email: meData['email'],
      targetWeight: target['value'].toDouble(),
    );
    return updated;
  }

  Future<List<DetailInfo>> getDailyNorms() async {
    final result = await _api.getDailyNorms();

    return Future.value([
      result.toDetailCaloriesIntake(),
      result.toDetailProteinIntake(),
      result.toDetailFatIntake(),
      result.toDetailCarbohydrateIntake(),
      result.toDetailWaterIntake(),
      result.toDetailStepIntake(),
    ]);
  }

  @override
  Future<void> updateProfile(ProfileRequest request) async {
    double? calculatedBmi;
    if (request.weight != null && request.height != null && request.height! > 0) {
      final heightInMeters = request.height! / 100;
      calculatedBmi = request.weight! / (heightInMeters * heightInMeters);
      calculatedBmi = double.parse(calculatedBmi.toStringAsFixed(2));
    }
    final updatedRequest = request.copyWith(bmi: calculatedBmi);
    final data = updatedRequest.toJson();
    data.removeWhere((key, value) => value == null);
    await _api.updateProfile(data);
  }

  @override
  Future<List<DetailInfo>> getProfileDetail() async {
    final profileRequest = await getProfile();
    return profileRequest.toDetailInfoList();
  }

  @override
  Future<void> updateSingleNorm(NormsRequest request) async {
    await _api.updateSingleNorm(request);
  }

  @override
  Future<void> logOut() async {
    await _api.logout();
  }
}
