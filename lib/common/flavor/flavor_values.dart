import 'package:rx_shared_preferences/rx_shared_preferences.dart';

class FlavorValues {

  FlavorValues({required SharedPreferences sharedPreferences});

  static Future<FlavorValues> fromEnvironment(
    SharedPreferences sharedPreferences,
  ) async {
    return FlavorValues(sharedPreferences: sharedPreferences);
  }
}
