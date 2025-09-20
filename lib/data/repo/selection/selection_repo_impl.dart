import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
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
      name: Strings.male,
      icon: Assets.icons.icMale.path,
      isChecked: true,
    ),
    Selection(
      name: Strings.female,
      icon: Assets.icons.icFemale.path,
      isChecked: false,
    ),
  ];
  List<Selection> goals = [
    Selection(name: "Vazn yo’qotish (ozish)", isChecked: true),
    Selection(name: "Tanani xozirgi xolatda saqlash)", isChecked: false),
    Selection(name: "Mushaklarni rivojlantirish", isChecked: false),
  ];
  List<Selection> activityLevels = [
    Selection(name: "Minimal aktivlik", isChecked: false),
    Selection(name: "Kam aktivlik", isChecked: false),
    Selection(name: "O’rtacha aktivlik", isChecked: true),
    Selection(name: "Yuqori aktivlik", isChecked: false),
    Selection(name: "Juda yuqori aktivlik", isChecked: false),
  ];
  List<Selection> metrics = [
    Selection(name: "Funt / fut / mil ", isChecked: false),
    Selection(name: "km / sm / kg ", isChecked: true),
  ];
}
