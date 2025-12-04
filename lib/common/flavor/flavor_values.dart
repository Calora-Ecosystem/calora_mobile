import 'package:rx_shared_preferences/rx_shared_preferences.dart';

class FlavorValues {
  bool isLogin;

  FlavorValues({required SharedPreferences sharedPreferences})
    : isLogin = bool.tryParse(sharedPreferences.getString('isLogin') ?? "false")??false;

  static Future<FlavorValues> fromEnvironment(
    SharedPreferences sharedPreferences,
  ) async {
    return FlavorValues(sharedPreferences: sharedPreferences);
  }
}
