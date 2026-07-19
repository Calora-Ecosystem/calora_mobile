import 'package:calora/data/api/country_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/country/country_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CountryRepo)
class CountryRepoImpl implements CountryRepo {
  final CountryApi _countryApi;
  final AuthStore _authStore;

  CountryRepoImpl(this._countryApi, this._authStore);

  @override
  Future<bool?> getCachedIsUzbekistan() => _authStore.isCountryUzbekistan();

  @override
  Future<bool> fetchIsUzbekistan() async {
    final bool response = await _countryApi.getCurrentCountry();
    await _authStore.isCountryUzbekistan.set(response);
    return response;
  }
}
