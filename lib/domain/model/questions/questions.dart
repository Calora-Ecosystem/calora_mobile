import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions.freezed.dart';
part 'questions.g.dart';

enum ActivityLevelEnum {
  Minimal,
  Less,
  Medium,
  High,
  Maximal,
  Unknown;

  bool get isMinimal => this == ActivityLevelEnum.Minimal;
  bool get isLess => this == ActivityLevelEnum.Less;
  bool get isMedium => this == ActivityLevelEnum.Medium;
  bool get isHigh => this == ActivityLevelEnum.High;
  bool get isMaximal => this == ActivityLevelEnum.Maximal;
  bool get isUnknown => this == ActivityLevelEnum.Unknown;

  String get displayName {
    switch (this) {
      case ActivityLevelEnum.Minimal:
        return Strings.minActivity;
      case ActivityLevelEnum.Less:
        return Strings.lowActivity;
      case ActivityLevelEnum.Medium:
        return Strings.averageActivity;
      case ActivityLevelEnum.High:
        return Strings.highActivity;
      case ActivityLevelEnum.Maximal:
        return Strings.veryHighActivity;
      case ActivityLevelEnum.Unknown:
        return 'Unknown';
    }
  }

  String toApi() {
    switch (this) {
      case ActivityLevelEnum.Minimal:
        return 'Minimal';
      case ActivityLevelEnum.Less:
        return 'Less';
      case ActivityLevelEnum.Medium:
        return 'Medium';
      case ActivityLevelEnum.High:
        return 'High';
      case ActivityLevelEnum.Maximal:
        return 'Maximal';
      case ActivityLevelEnum.Unknown:
        return 'Unknown';
    }
  }

  static ActivityLevelEnum fromApi(String value) {
    switch (value) {
      case 'Minimal':
        return ActivityLevelEnum.Minimal;
      case 'Less':
        return ActivityLevelEnum.Less;
      case 'Medium':
        return ActivityLevelEnum.Medium;
      case 'High':
        return ActivityLevelEnum.High;
      case 'Maximal':
        return ActivityLevelEnum.Maximal;
      default:
        return ActivityLevelEnum.Unknown;
    }
  }

  static ActivityLevelEnum fromDisplayName(String value) {
    if (value == Strings.minActivity) return ActivityLevelEnum.Minimal;
    if (value == Strings.lowActivity) return ActivityLevelEnum.Less;
    if (value == Strings.averageActivity) return ActivityLevelEnum.Medium;
    if (value == Strings.highActivity) return ActivityLevelEnum.High;
    if (value == Strings.veryHighActivity) return ActivityLevelEnum.Maximal;
    return ActivityLevelEnum.Unknown;
  }
}

@freezed
abstract class Questions with _$Questions {
  const factory Questions({
    String? name,
    Gender? gender,
    double? entryWeight,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? targetWeight,
    String? activityHours,
  }) = _Questions;

  factory Questions.fromJson(Map<String, dynamic> json) =>
      _$QuestionsFromJson(json);
}
