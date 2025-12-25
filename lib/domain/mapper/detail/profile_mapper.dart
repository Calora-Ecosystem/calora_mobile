import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

extension ProfileRequestToDetailInfos on ProfileRequest {
  List<DetailInfo> toDetailInfoList() {
    return [
      DetailInfo(title: Strings.name, message: name ?? '', type: DetailInfoType.name),
      DetailInfo(title: Strings.birthday, message: birthDay ?? '', type: DetailInfoType.birthDay),
      DetailInfo(title: Strings.goal, message: goal ?? '', type: DetailInfoType.goal),
      DetailInfo(
        title: Strings.activityLevel,
        message: activityLevel?.toString() ?? '',
        type: DetailInfoType.activityLevel,
      ),
      DetailInfo(title: Strings.metrics, message: metrics ?? '', type: DetailInfoType.metrics),
      // DetailInfo(title: Strings.emailAddress, message: email ?? "", type: DetailInfoType.email),
      // DetailInfo(title: 'Bmi', message: bmi?.toString() ?? "", type: DetailInfoType.bmi),
      DetailInfo(title: Strings.gender, message: gender ?? '', type: DetailInfoType.gender),
      DetailInfo(
        title: Strings.height,
        message: height?.toString() ?? '',
        metric: 'sm',
        type: DetailInfoType.height,
      ),
      DetailInfo(
        title: Strings.weight,
        message: weight?.toString() ?? '',
        metric: 'kg',
        type: DetailInfoType.weight,
      ),
      // DetailInfo(
      //   title: 'Target',
      //   message: targetWeight?.toString() ?? "",
      //   metric: "kg",
      //   type: DetailInfoType.targetWeight,
      // ),
    ];
  }
}
