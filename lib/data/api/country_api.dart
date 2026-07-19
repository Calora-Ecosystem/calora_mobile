import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class CountryApi {
  final Dio _dio;

  CountryApi(@Named('country') this._dio);

  Future<bool> getCurrentCountry() async {
    final response = await _dio.get('/');
    final String countryCode =
        (response.data as Map<String, dynamic>)['country'];
    return countryCode.toUpperCase() == 'UZ';
  }
}
