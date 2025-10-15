import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/mapper/detail/account_detail_mapper.dart';
import 'package:calora/domain/mapper/detail/detail_mapper.dart';
import 'package:calora/domain/mapper/detail/profile_request_mapper.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/norms/daily_norms_info.dart';
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
    print('-------------${target['value']}');
    final profile = ProfileRequest.fromJson(extrasData);

    final updated = profile.copyWith(
      email: meData['email'],
      targetWeight: target['value'].toDouble(),
    );
    return updated;
  }

  Future<List<DetailInfo>> getDailyNorms() async {
    var result = await _api.getDailyNorms();

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
    final profile = profileRequest.toProfile();
    return profile.toDetailInfoList();
  }

  @override
  Future<void> updateDailyNorms(DailyNormsInfo dailyNormsInfo) {
    return _api.updateDailyNorms(dailyNormsInfo);
  }

  List<DetailInfo> normsList = [
    DetailInfo(
      title: Strings.dailyCalorieIntake,
      message: "2500",
      metric: "kcal",
      type: DetailInfoType.dailyCalorieNorm,
    ),
    DetailInfo(
      title: Strings.dailyProteinIntake,
      message: "200",
      metric: "gr",
      type: DetailInfoType.dailyProteinNorm,
    ),
    DetailInfo(
      title: Strings.dailyFatIntake,
      message: "300",
      metric: "gr",
      type: DetailInfoType.dailyFatNorm,
    ),
    DetailInfo(
      title: Strings.dailyCarbohydradeIntake,
      message: "340",
      metric: "gr",
      type: DetailInfoType.dailyCarbohydrateNorm,
    ),
    DetailInfo(
      title: Strings.dailyWaterIntake,
      message: "2200",
      metric: 'ml',
      type: DetailInfoType.dailyWaterNorm,
    ),
    DetailInfo(
      title: Strings.dailyStepRate,
      message: "20000",
      metric: "qadam",
      type: DetailInfoType.dailyStepNorm,
    ),
  ];

  List<DetailInfo> detailInfos = [
    DetailInfo(title: Strings.name, message: "Nurbek", type: DetailInfoType.name),
    DetailInfo(title: Strings.lastName, message: "", type: DetailInfoType.lastName),
    DetailInfo(title: Strings.birthday, message: "1999-08-06", type: DetailInfoType.birthDay),
    DetailInfo(title: Strings.height, message: "165", metric: "sm", type: DetailInfoType.height),
    DetailInfo(title: Strings.weight, message: "75", metric: "kg", type: DetailInfoType.weight),
    DetailInfo(title: Strings.gender, message: "Erkak", type: DetailInfoType.gender),
    DetailInfo(title: Strings.goal, message: "Maqsad", type: DetailInfoType.goal),
    DetailInfo(
      title: Strings.activityLevel,
      message: "O'rtacha",
      type: DetailInfoType.activityLevel,
    ),
    DetailInfo(title: Strings.metrics, message: "km/sm/kg", type: DetailInfoType.metrics),
  ];
}
