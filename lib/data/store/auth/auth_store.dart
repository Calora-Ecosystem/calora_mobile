import 'dart:async';
import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthStore {
  final token = BaseStore<Token?>(
    'token',
    serialize: (value) => value == null ? null : jsonEncode(value.toJson()),
    deserialize: (value) => value == null ? null : Token.fromJson(jsonDecode(value)),
  );

  final isCountryUzbekistan = BaseStore<bool>(
    'isCountryUzbekistan1',
    serialize: (value) => value.toString(),
    deserialize: (value) => value == 'true',
  );

  final _forceLogoutController = StreamController<void>.broadcast();
  Stream<void> get onForceLogout => _forceLogoutController.stream;

  void forceLogout() {
    _forceLogoutController.add(null);
  }
}
