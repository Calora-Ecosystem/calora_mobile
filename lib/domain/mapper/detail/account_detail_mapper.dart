// lib/domain/mapper/profile/profile_detail_mapper.dart
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/detail/detail_info_type.dart';
import 'package:calora/domain/model/profile/profile.dart';

extension ProfileToDetailInfos on Profile {
  List<DetailInfo> toDetailInfoList() {
    return [
      DetailInfo(title: Strings.name, message: firstName ?? "", type: DetailInfoType.name),
      DetailInfo(title: Strings.lastName, message: lastName ?? "", type: DetailInfoType.lastName),
      DetailInfo(title: Strings.birthday, message: birthDate ?? "", type: DetailInfoType.birthDay),
      DetailInfo(
        title: Strings.height,
        message: height?.toString() ?? "",
        metric: "sm",
        type: DetailInfoType.height,
      ),
      DetailInfo(
        title: Strings.weight,
        message: weight?.toString() ?? "",
        metric: "kg",
        type: DetailInfoType.weight,
      ),
      DetailInfo(title: Strings.gender, message: gender ?? "", type: DetailInfoType.gender),
      DetailInfo(title: Strings.goal, message: goal ?? "", type: DetailInfoType.goal),
      DetailInfo(
        title: Strings.activityLevel,
        message: activateStatus ?? "",
        type: DetailInfoType.activityLevel,
      ),
      DetailInfo(
        title: Strings.metrics,
        message: metrics?.join('/') ?? "",
        type: DetailInfoType.metrics,
      ),
    ];
  }
}
