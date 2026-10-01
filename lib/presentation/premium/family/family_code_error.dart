import 'package:calora/common/extensions/api_error_extension.dart';
import 'package:easy_localization/easy_localization.dart';

/// Maps the backend's family-code error codes to a user-facing message.
String familyCodeErrorText(Object error) => switch (error.apiErrorCode) {
  'family_code_not_found' => 'family_err_not_found'.tr(),
  'family_code_used' => 'family_err_used'.tr(),
  'family_code_expired' => 'family_code_expired'.tr(),
  'family_code_self' => 'family_err_self'.tr(),
  _ => 'something_went_wrong'.tr(),
};
