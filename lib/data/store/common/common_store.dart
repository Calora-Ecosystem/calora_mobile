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

  final isLanguageSelected = BaseStore<bool>(
    'isLanguageSelected',
    serialize: (value) => value.toString(),
    deserialize: (value) => value == 'true',
  );
  final isOnboardingCompleted = BaseStore<bool>(
    'isOnboardingCompleted',
    serialize: (value) => value.toString(),
    deserialize: (value) => value == 'true',
  );

  final isQuestionaryFinished = BaseStore<bool>(
    'isQuestionaryFinished',
    serialize: (value) => value.toString(),
    deserialize: (value) => value == 'true',
  );
}
