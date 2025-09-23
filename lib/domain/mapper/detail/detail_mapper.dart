import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/norms/daily_norms_info.dart';

extension DailyNormsInfoExtension on DailyNormsInfo {
  DetailInfo toDetailCaloriesIntake() {
    return DetailInfo(
      title: Strings.dailyCalorieIntake,
      id: 'daily_calorie_intake',
      message: calories.toString(),
      metric: 'kcal',
      type: DetailInfoType.dailyCalorieNorm,
    );
  }

  DetailInfo toDetailProteinIntake() {
    return DetailInfo(
      title: Strings.dailyProteinIntake,
      id: 'daily_protein_intake',
      message: protein.toString(),
      metric: 'gr',
      type: DetailInfoType.dailyProteinNorm,
    );
  }

  DetailInfo toDetailFatIntake() {
    return DetailInfo(
      title: Strings.dailyFatIntake,
      id: 'daily_fat_intake',
      message: fat.toString(),
      metric: 'gr',
      type: DetailInfoType.dailyFatNorm,
    );
  }

  DetailInfo toDetailCarbohydrateIntake() {
    return DetailInfo(
      title: Strings.dailyCarbohydradeIntake,
      id: 'daily_carbohydrate_intake',
      message: carbs.toString(),
      metric: 'gr',
      type: DetailInfoType.dailyCarbohydrateNorm,
    );
  }

  DetailInfo toDetailWaterIntake() {
    return DetailInfo(
      title: Strings.dailyWaterIntake,
      id: 'daily_water_intake',
      message: water.toString(),
      metric: 'ml',
      type: DetailInfoType.dailyWaterNorm,
    );
  }

  DetailInfo toDetailStepIntake() {
    return DetailInfo(
      title: Strings.dailyStepRate,
      id: 'daily_step_intake',
      message: steps.toString(),
      metric: 'steps',
      type: DetailInfoType.dailyStepNorm,
    );
  }
}
