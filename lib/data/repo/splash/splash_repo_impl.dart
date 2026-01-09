import 'package:calora/data/api/splash_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/splash/splash_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: SplashRepo)
class SplashRepoImpl implements SplashRepo {
  final SplashApi _splashApi;
  final AuthStore _authStore;

  SplashRepoImpl(this._splashApi, this._authStore);

  @override
  Future<bool> getCurrentCountry() async {
    final bool response = await _splashApi.getCurrentCountry();
    await _authStore.isCountryUzbekistan.set(response);
    return response;
  }
}
