import 'package:calora/common/di/injection.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/common/util/cached.dart';
import 'package:calora/data/api/common_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_detector/country_detector.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@Injectable(as: CommonRepo)
class CommonRepoImpl extends CommonRepo {
  final CommonStore _commonStore;
  final AuthStore _store;
  final CommonApi _commonApi;
  final RevenueCatService _revenueCatService;
  final Connectivity _connectivity;
  final CountryDetector _countryDetector;

  CommonRepoImpl(
    this._commonStore,
    this._store,
    this._commonApi,
    this._revenueCatService,
    this._connectivity,
    this._countryDetector,
  );

  @override
  Cached<bool> getIsUzbekistan() => Cached(
    store: _store.isCountryUzbekistan,
    fetch: _resolveIsUzbekistan,
  );

  Future<bool> _resolveIsUzbekistan() async {
    if (await _isUzbekistanBySim()) return true;
    if (await _isUzbekistanByPhone()) return true;
    if (await _isUzbekistanByStorefront()) return true;
    if (await _isUzbekistanByIp()) return true;
    return _isUsingVpn();
  }

  Future<bool> _isUzbekistanBySim() async {
    try {
      final countries = await _countryDetector.detectAll();
      return countries.sim.toUpperCase() == 'UZ' ||
          countries.network.toUpperCase() == 'UZ';
    } catch (e, st) {
      getIt<Logger>().e('SIM country lookup failed: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> _isUzbekistanByIp() async {
    try {
      return await _commonApi.getCurrentCountry();
    } catch (e, st) {
      getIt<Logger>().e('Country IP lookup failed: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> _isUzbekistanByStorefront() async {
    try {
      return await _revenueCatService.storefrontCountryCode() == 'UZ';
    } catch (e, st) {
      // Never let one signal's failure abort the whole resolution chain
      // (this was the only unguarded check — a RevenueCat hiccup used to
      // throw out of _resolveIsUzbekistan entirely).
      getIt<Logger>().e('Storefront country lookup failed: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> _isUzbekistanByPhone() async {
    final phone = await _store.phone();
    return phone != null && phone.replaceAll(' ', '').startsWith('+998');
  }

  Future<bool> _isUsingVpn() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.vpn);
    } catch (e, st) {
      getIt<Logger>().e('VPN check failed: $e', stackTrace: st);
      return false;
    }
  }

  @override
  Future<void> setSelectedLanguage(Language language) {
    return _commonStore.language.set(language);
  }

  @override
  Future<Language> getSelectedLanguage() async {
    final result = await _commonStore.language.call();
    return result ?? Language.UZ;
  }

  @override
  Future<void> setLanguageSelectedFlag(bool value) async {
    return _commonStore.isLanguageSelected.set(value);
  }

  @override
  Future<void> setOnboardingCompletedFlag(bool value) {
    return _commonStore.isOnboardingCompleted.set(value);
  }
}
