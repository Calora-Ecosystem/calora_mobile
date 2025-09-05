import 'package:calora/common/flavor/flavor_values.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

class FlavorConfig {
  static late FlavorValues _flavorValues;

  static var _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      final sharedPreferences = await SharedPreferences.getInstance();
      _flavorValues = await FlavorValues.fromEnvironment(sharedPreferences);
      _initialized = true;
    }
  }

  static bool get isLogin => _flavorValues.isLogin;
}
