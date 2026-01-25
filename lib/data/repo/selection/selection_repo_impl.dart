import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/selection/Selection.dart';
import 'package:calora/domain/model/selection/selection_type.dart';
import 'package:calora/domain/repo/selection/selection_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: SelectionRepo)
class SelectionRepoImpl extends SelectionRepo {
  @override
  Future<List<Selection>> getSelections(Selection selection) {
    switch (selection.type) {
      case SelectionType.activityLevel:
        return Future.value(activityLevels);
      case SelectionType.goal:
        return Future.value(goals);
      case SelectionType.gender:
        return Future.value(genders);
      case SelectionType.metrics:
        return Future.value(metrics);
      default:
        return Future.value();
    }
  }

  List<Selection> genders = [
    Selection(
      name: Gender.Male.displayName,
      icon: Assets.icons.icMale.path,
      isChecked: true,
    ),
    Selection(
      name: Gender.Female.displayName,
      icon: Assets.icons.icFemale.path,
    ),
  ];
  List<Selection> goals = [
    Selection(
      name: PurposeEnum.WeightLoss.displayName,
      isChecked: true,
      id: '1',
    ),
    Selection(name: PurposeEnum.SaveCurrent.displayName, id: '2'),
    Selection(name: PurposeEnum.MuscleDevelopment.displayName, id: '3'),
  ];
  List<Selection> activityLevels = [
    Selection(name: ActivityLevelEnum.Minimal.displayName, id: '1'),
    Selection(name: ActivityLevelEnum.Less.displayName, id: '2'),
    Selection(
      name: ActivityLevelEnum.Medium.displayName,
      isChecked: true,
      id: '3',
    ),
    Selection(name: ActivityLevelEnum.High.displayName, id: '4'),
    Selection(name: ActivityLevelEnum.Maximal.displayName, id: '5'),
  ];
  List<Selection> metrics = [
    Selection(name: 'Funt / fut / mil ', id: '1'),
    Selection(name: 'km / sm / kg ', isChecked: true, id: '2'),
  ];
}
