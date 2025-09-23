import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

extension AccountDetailMapper on ProfileRequest {
  DetailInfo toDetailName() {
    return DetailInfo(
      title: 'Name',
      id: 'name',
      message: name,
      metric: '',
      type: DetailInfoType.name,
    );
  }

  DetailInfo toDetailUserId() {
    return DetailInfo(
      title: 'User ID',
      id: 'user_id',
      message: userId,
      metric: '',
      type: DetailInfoType.userId,
    );
  }

  DetailInfo toDetailEmail() {
    return DetailInfo(
      title: 'Email',
      id: 'email',
      message: email,
      metric: '',
      type: DetailInfoType.email,
    );
  }

  DetailInfo toDetailGender() {
    return DetailInfo(
      title: 'Gender',
      id: 'gender',
      message: gender,
      metric: '',
      type: DetailInfoType.gender,
    );
  }

  DetailInfo toDetailHeight() {
    return DetailInfo(
      title: 'Height',
      id: 'height',
      message: height.toString(),
      metric: 'sm',
      type: DetailInfoType.height,
    );
  }

  DetailInfo toDetailWeight() {
    return DetailInfo(
      title: 'Weight',
      id: 'weight',
      message: weight.toString(),
      metric: 'kg',
      type: DetailInfoType.weight,
    );
  }

  DetailInfo toDetailTargetWeight() {
    return DetailInfo(
      title: 'Target Weight',
      id: 'target_weight',
      message: targetWeight.toString(),
      metric: 'kg',
      type: DetailInfoType.targetWeight,
    );
  }

  DetailInfo toDetailBmi() {
    return DetailInfo(
      title: 'BMI',
      id: 'bmi',
      message: bmi.toString(),
      metric: '',
      type: DetailInfoType.bmi,
    );
  }

  DetailInfo toDetailBirthday() {
    return DetailInfo(
      title: 'Birthday',
      id: 'birthday',
      message: birthDay,
      metric: '',
      type: DetailInfoType.birthDay,
    );
  }

  DetailInfo toDetailGoal() {
    return DetailInfo(
      title: 'Goal',
      id: 'goal',
      message: goal,
      metric: '',
      type: DetailInfoType.goal,
    );
  }

  DetailInfo toDetailActivityLevel() {
    return DetailInfo(
      title: 'Activity Level',
      id: 'activity_level',
      message: activityLevel,
      metric: '',
      type: DetailInfoType.activityLevel,
    );
  }
}
