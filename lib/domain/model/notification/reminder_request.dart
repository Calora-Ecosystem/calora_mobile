import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_request.freezed.dart';
part 'reminder_request.g.dart';

@freezed
abstract class ReminderRequest with _$ReminderRequest {
  const factory ReminderRequest({
    required String time,
    required String type,
    required String menu,
    int? id,
  }) = _ReminderRequest;

  factory ReminderRequest.fromJson(Map<String, dynamic> json) => _$ReminderRequestFromJson(json);
}
