import 'package:calora/common/constants/app_links.dart';
import 'package:easy_localization/easy_localization.dart';

// Invite messages for the share sheet. They are translated at the moment the
// user taps share, so a message always goes out in the language the app's
// interface is set to, and each one carries the plain [appDownloadLink].

/// Step challenge invite: the group, its invite code and where to get the app.
String groupInviteShareText({
  required String groupName,
  required String code,
}) => [
  'share_group_invite'.tr(namedArgs: {'name': groupName}),
  'share_group_code'.tr(namedArgs: {'code': code}),
  'share_app_download'.tr(namedArgs: {'link': appDownloadLink}),
].join('\n\n');

/// Referral invite: the code, the friend's Premium discount and the link.
String referralShareText({required String code, required int percent}) =>
    'referral_share_text'.tr(
      namedArgs: {'code': code, 'percent': '$percent', 'link': appDownloadLink},
    );
