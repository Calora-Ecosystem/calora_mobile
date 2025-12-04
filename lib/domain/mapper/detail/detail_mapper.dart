import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/norms/daily_norms_info.dart';

extension DailyNormsInfoExtension on DailyNormsInfo {
  DetailInfo toDetailCaloriesIntake() {
    return DetailInfo(
      title: Strings.dailyCalorieIntake,
      id: 'daily_calorie_intake',
      message: calories.asFixedTruncated(2).toString(),
      metric: 'kcal',
      type: DetailInfoType.dailyCalorieNorm,
    );
  }

  DetailInfo toDetailProteinIntake() {
    return DetailInfo(
      title: Strings.dailyProteinIntake,
      id: 'daily_protein_intake',
      message: protein.asFixedTruncated(2).toString(),
      metric: 'gr',
      type: DetailInfoType.dailyProteinNorm,
    );
  }

  DetailInfo toDetailFatIntake() {
    return DetailInfo(
      title: Strings.dailyFatIntake,
      id: 'daily_fat_intake',
      message: fat.asFixedTruncated(2).toString(),
      metric: 'gr',
      type: DetailInfoType.dailyFatNorm,
    );
  }

  DetailInfo toDetailCarbohydrateIntake() {
    return DetailInfo(
      title: Strings.dailyCarbohydradeIntake,
      id: 'daily_carbohydrate_intake',
      message: carbs.asFixedTruncated(2).toString(),
      metric: 'gr',
      type: DetailInfoType.dailyCarbohydrateNorm,
    );
  }

  DetailInfo toDetailWaterIntake() {
    return DetailInfo(
      title: Strings.dailyWaterIntake,
      id: 'daily_water_intake',
      message: water.asFixedTruncated(2).toString(),
      metric: 'ml',
      type: DetailInfoType.dailyWaterNorm,
    );
  }

  DetailInfo toDetailStepIntake() {
    return DetailInfo(
      title: Strings.dailyStepRate,
      id: 'daily_step_intake',
      message: steps.asFixedTruncated(2).toString(),
      metric: 'steps',
      type: DetailInfoType.dailyStepNorm,
    );
  }
}
