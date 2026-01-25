import 'package:calora/common/di/injection.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

class BaseStore<T> {
  BaseStore(
    this.key, {
    required this.serialize,
    required this.deserialize,
    Future<String> Function()? suffixer,
  }) : suffixer = suffixer ?? (() async => '');

  final _preferences = getIt<RxSharedPreferences>();
  final String key;
  final String? Function(T value) serialize;
  final T Function(String? value) deserialize;
  Future<String> Function() suffixer;

  Future<void> set(T value) async {
    return _preferences.setString(key + await suffixer(), serialize(value));
  }

  Future<T> call() async {
    final value = await _preferences.getString(key + await suffixer());

    return deserialize(value);
  }

  Future<void> clear() async {
    return _preferences.remove(key + await suffixer());
  }

  Future<void> update(T Function(T value) update) async {
    final value = await call();
    return set(update(value));
  }

  Stream<T> watch() async* {
    final suffixed = key + await suffixer();
    yield* _preferences.getStringStream(suffixed).map(deserialize);
  }
}
