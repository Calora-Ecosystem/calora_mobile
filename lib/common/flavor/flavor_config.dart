import 'package:calora/common/flavor/flavor_values.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Keep SharedPreferences import

class FlavorConfig {
  static late FlavorValues _flavorValues;

  static var _initialized = false;

  static Future<void> initialize(SharedPreferences sharedPreferences) async { // Modified to accept SharedPreferences
    if (!_initialized) {
      _flavorValues = await FlavorValues.fromEnvironment(sharedPreferences); // Use injected instance
      _initialized = true;
    }
  }
}
