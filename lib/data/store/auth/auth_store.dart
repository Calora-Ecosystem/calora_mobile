import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthStore {
  final token = BaseStore<Token?>(
    'token',
    serialize: (value) => value == null ? null : jsonEncode(value.toJson()),
    deserialize: (value) =>
        value == null ? null : Token.fromJson(jsonDecode(value)),
  );

  final isLogin = BaseStore<bool?>(
    'isLogin',
    serialize: (value) => jsonEncode(value),
    deserialize: (value) => bool.tryParse(value??"false"),
  );
}
