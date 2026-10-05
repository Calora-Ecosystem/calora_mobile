import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/domain/model/calories/ai_quota.dart';
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

  final isUserPremium = BaseStore<bool>(
    'isUserPremium',
    serialize: (value) => value.toString(),
    deserialize: (value) => value == 'true',
  );

  final aiQuota = BaseStore<AiQuota>(
    'aiQuota',
    serialize: (value) => jsonEncode(value.toJson()),
    deserialize: (value) {
      if (value == null) return const AiQuota();
      try {
        return AiQuota.fromJson(jsonDecode(value) as Map<String, dynamic>);
      } catch (_) {
        return const AiQuota();
      }
    },
  );
}
