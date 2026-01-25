import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfigs {
  static String baseUrl = dotenv.env['BASE_URL'] ?? '';
  static String stagingBaseUrl = 'https://staging.calora.uz/api/';
}
