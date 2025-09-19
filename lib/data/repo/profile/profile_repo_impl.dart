import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/norms/daily_norms_request.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/repo/profile_repo.dart';
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
  Future<void> logout() {
    return _api.logout();
  }
}
