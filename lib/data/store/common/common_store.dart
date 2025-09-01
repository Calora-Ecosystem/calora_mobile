import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CommonStore {
  final language = BaseStore<Language?>(
    'language',
    serialize: (value) => value == null ? null : jsonEncode(value.name),
    deserialize: (value) =>
        value == null ? null : Language.fromName(jsonDecode(value)),
  );
}
