import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_request.freezed.dart';
part 'reminder_request.g.dart';

@freezed
abstract class ReminderRequest with _$ReminderRequest {
  const factory ReminderRequest({
    int? id,
    String? time,
    String? type,
    String? menu,
    @Default(true) bool isActive,
  }) = _ReminderRequest;

  factory ReminderRequest.fromJson(Map<String, dynamic> json) =>
      _$ReminderRequestFromJson(json);

  static List<ReminderRequest> fromJsonList(List<dynamic> json) =>
      json.map((e) => ReminderRequest.fromJson(e)).toList();
}
