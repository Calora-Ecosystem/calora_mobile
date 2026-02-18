import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@unfreezed
abstract class Notification with _$Notification {
  factory Notification({
    required int id,
    required int userId,
    required String title,
    String? description,
    required bool hasRead,
    required DateTime sentAt,
    String? image,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}
