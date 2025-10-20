import 'package:calora/common/base/gender_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/repo/home/home_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: HomeRepo)
class HomeRepoImpl implements HomeRepo {
  final ProfileApi profileApi;

  HomeRepoImpl(this.profileApi);

  @override
  Future<void> getUserGender() async {
    var response = await profileApi.getProfileExtras();
    var data = response.data['content'];
    await getIt<GenderStore>().setFromString(data['gender']);
    print(data['gender']);
  }
}
