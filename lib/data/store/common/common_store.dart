import 'dart:convert';

import 'package:calora/common/base/base_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CommonStore {
  final language = BaseStore<Language?>(
    'language',
    serialize: (value) => value == null ? null : jsonEncode(value.name),
    deserialize: (value) => value == null ? null : Language.fromName(jsonDecode(value)),
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

  /// Cached server count of free AI recognitions (photo scan + voice add) a
  /// non-premium user has used. The server is the source of truth
  /// (`food/recognization/quota`, refreshed by `AiQuotaService`); this cache
  /// only lets the banner render instantly.
  final freeAiScansUsed = BaseStore<int>(
    'freeAiScansUsed',
    serialize: (value) => value.toString(),
    deserialize: (value) => int.tryParse(value ?? '') ?? 0,
  );

  /// Cached server limit (free allowance + bonus scans bought with coins).
  final freeAiScanLimit = BaseStore<int>(
    'freeAiScanLimit',
    serialize: (value) => value.toString(),
    deserialize: (value) => int.tryParse(value ?? '') ?? kFreeAiScanLimit,
  );
}

/// Default number of free AI recognitions for non-premium users, used until
/// the server's quota is known. Shared across photo scanning and voice add.
const int kFreeAiScanLimit = 5;
