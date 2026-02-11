import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class SplashApi {
  final Dio _dio;

  SplashApi(@Named('country') this._dio);

  Future<bool> getCurrentCountry() async {
    final response = await _dio.get('/');
    final String countryCode = (response.data as Map<String, dynamic>)['country'];
    return countryCode.toUpperCase() == 'UZ';
  }
}
