import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';

class DetailInfo {
  final String title;
  final String message;
  final String metric;
  final DetailInfoType type;

  DetailInfo({
    this.title = "",
    this.message = "",
    this.metric = "",
    this.type = DetailInfoType.none,
  });

  bool get isHaveMessage => message.isNotEmpty;

  String get resultMessage => isHaveMessage ? "$message $metric" : Strings.input;

  DetailInfo copyWith({
    String? title,
    String? message,
    String? metric,
    DetailInfoType? type,
  }) {
    return DetailInfo(
      title: title ?? this.title,
      message: message ?? this.message,
      metric: metric ?? this.metric,
      type: type ?? this.type,
    );
  }
}
