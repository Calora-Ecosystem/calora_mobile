import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/norms/daily_norms_request.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ProfileRepo)
class ProfileRepoImpl extends ProfileRepo {
  final ProfileApi _api;

  ProfileRepoImpl(this._api);

  @override
  Future<ProfileRequest> getProfile() {
    return _api.getProfile();
  }

  Future<DailyNormsRequest> getDailyNorms() {
    return _api.getDailyNorms();
  }

  @override
  Future<List<DetailInfo>> getProfileDetail() {
    return Future.value(detailInfos);
  }

  @override
  Future<void> logout() {
    return _api.logout();
  }

  List<DetailInfo> detailInfos = [
    DetailInfo(
      title: Strings.name,
      message: "Nurbek",
      type: DetailInfoType.name,
    ),
    DetailInfo(
      title: Strings.lastName,
      message: "",
      type: DetailInfoType.lastName,
    ),
    DetailInfo(
      title: Strings.birthday,
      message: "1999-08-06",
      type: DetailInfoType.birthDay,
    ),
    DetailInfo(
      title: Strings.height,
      message: "165",
      metric: "sm",
      type: DetailInfoType.height,
    ),
    DetailInfo(
      title: Strings.weight,
      message: "75",
      metric: "kg",
      type: DetailInfoType.weight,
    ),
    DetailInfo(
      title: Strings.gender,
      message: "Erkak",
      type: DetailInfoType.gender,
    ),
    DetailInfo(
      title: Strings.goal,
      message: "Maqsad",
      type: DetailInfoType.goal,
    ),
    DetailInfo(
      title: Strings.activityLevel,
      message: "O'rtacha",
      type: DetailInfoType.activityLevel,
    ),
    DetailInfo(
      title: Strings.metrics,
      message: "km/sm/kg",
      type: DetailInfoType.metrics,
    ),
  ];
}
