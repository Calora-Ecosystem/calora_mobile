import 'package:calora/common/date/date_formatter.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/questions/questions.dart'; // For ActivityLevelEnum
import 'package:calora/domain/model/questions/questions_request.dart'; // For PurposeEnum
import 'package:calora/common/base/profile_store.dart'; // For Gender
import 'package:flutter/cupertino.dart';

class DetailInfo {
  final String id;
  final String title;
  final String message;
  final String metric;
  final DetailInfoType type;

  DetailInfo({
    this.title = '',
    this.id = '',
    this.message = '',
    this.metric = '',
    this.type = DetailInfoType.none,
  });

  bool get isHaveMessage => message.isNotEmpty;

  String get resultMessage {
    switch (type) {
      case DetailInfoType.birthDay:
        return prettyDateVision;
      case DetailInfoType.activityLevel:
        return ActivityLevelEnum.fromApi(message).displayName;
      case DetailInfoType.goal:
        return PurposeEnum.fromApi(message).displayName;
      case DetailInfoType.gender:
        return Gender.fromApi(message).displayName;
      default:
        return isHaveMessage ? '$message $metric' : Strings.input;
    }
  }

  String get prettyDateVision => DateFormatter.getBirthDate(message);

  TextInputType get currentTextInputType =>
      type == DetailInfoType.name || type == DetailInfoType.lastName
      ? TextInputType.name
      : TextInputType.number;

  DetailInfo copyWith({
    String? title,
    String? id,
    String? message,
    String? metric,
    DetailInfoType? type,
  }) {
    return DetailInfo(
      title: title ?? this.title,
      id: id ?? this.id,
      message: message ?? this.message,
      metric: metric ?? this.metric,
      type: type ?? this.type,
    );
  }
}
