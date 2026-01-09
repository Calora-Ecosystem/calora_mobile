import 'package:calora/common/gen/strings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions_request.freezed.dart';
part 'questions_request.g.dart';

enum PurposeEnum {
  WeightLoss,
  SaveCurrent,
  MuscleDevelopment,
  Unknown;

  bool get isWeightLoss => this == PurposeEnum.WeightLoss;
  bool get isSaveCurrent => this == PurposeEnum.SaveCurrent;
  bool get isMuscleDevelopment => this == PurposeEnum.MuscleDevelopment;
  bool get isUnknown => this == PurposeEnum.Unknown;

  String toApi() {
    switch (this) {
      case PurposeEnum.WeightLoss:
        return 'WeightLoss';
      case PurposeEnum.SaveCurrent:
        return 'SaveCurrent';
      case PurposeEnum.MuscleDevelopment:
        return 'MuscleDevelopment';
      case PurposeEnum.Unknown:
        return 'Unknown';
    }
  }

  String get displayName {
    switch (this) {
      case PurposeEnum.WeightLoss:
        return Strings.weightLoss;
      case PurposeEnum.SaveCurrent:
        return Strings.maintainingBody;
      case PurposeEnum.MuscleDevelopment:
        return Strings.muscleDevelopment;
      case PurposeEnum.Unknown:
        return 'Unknown';
    }
  }

  static PurposeEnum fromDisplayName(String value) {
    if (value == Strings.weightLoss) return PurposeEnum.WeightLoss;
    if (value == Strings.maintainingBody) return PurposeEnum.SaveCurrent;
    if (value == Strings.muscleDevelopment)
      return PurposeEnum.MuscleDevelopment;
    return PurposeEnum.Unknown;
  }

  static PurposeEnum fromApi(String value) {
    switch (value) {
      case 'WeightLoss':
        return PurposeEnum.WeightLoss;
      case 'SaveCurrent':
        return PurposeEnum.SaveCurrent;
      case 'MuscleDevelopment':
        return PurposeEnum.MuscleDevelopment;
      default:
        return PurposeEnum.Unknown;
    }
  }
}

@freezed
abstract class QuestionsRequest with _$QuestionsRequest {
  const factory QuestionsRequest({
    String? name,
    String? gender,
    String? purpose,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? bmi,
    double? targetWeight,
    String? activityLevel,
    String? photo,
    String? language,
  }) = _QuestionsRequest;

  factory QuestionsRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionsRequestFromJson(json);
}
