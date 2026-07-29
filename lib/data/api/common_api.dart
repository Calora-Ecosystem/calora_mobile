import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class CommonApi {
  final Dio _dio;

  CommonApi(@Named('country') this._dio);

  /// IP-based country check with a two-provider chain: api.country.is
  /// first, ipwho.is as fallback. Both are HTTPS, free, and return the
  /// ISO country code; if both fail the caller treats it as "unknown"
  /// (not Uzbekistan) and the other signals (SIM, phone, storefront)
  /// decide.
  Future<bool> getCurrentCountry() async {
    try {
      final response = await _dio.get('/');
      final String countryCode =
          (response.data as Map<String, dynamic>)['country'];
      return countryCode.toUpperCase() == 'UZ';
    } catch (_) {
      // Primary geo provider unreachable (blocked / offline / slow) —
      // fall through to the backup before giving up.
    }

    // Absolute URL bypasses the baseUrl; same short timeouts apply.
    final response = await _dio.get('https://ipwho.is/');
    final data = response.data as Map<String, dynamic>;
    final code = (data['country_code'] as String?) ?? '';
    return code.toUpperCase() == 'UZ';
  }
}
