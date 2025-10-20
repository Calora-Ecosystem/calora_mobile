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
    Selection(name: Strings.male, icon: Assets.icons.icMale.path, isChecked: true),
    Selection(name: Strings.female, icon: Assets.icons.icFemale.path, isChecked: false),
  ];
  List<Selection> goals = [
    Selection(name: "Vazn yo’qotish (ozish)", isChecked: true, id: '1'),
    Selection(name: "Tanani xozirgi xolatda saqlash)", isChecked: false, id: '2'),
    Selection(name: "Mushaklarni rivojlantirish", isChecked: false, id: '3'),
  ];
  List<Selection> activityLevels = [
    Selection(name: Strings.minActivity, isChecked: false, id: '1'),
    Selection(name: Strings.lowActivity, isChecked: false, id: '2'),
    Selection(name: Strings.averageActivity, isChecked: true, id: '3'),
    Selection(name: Strings.highActivity, isChecked: false, id: '4'),
    Selection(name: Strings.veryHighActivity, isChecked: false, id: '5'),
  ];
  List<Selection> metrics = [
    Selection(name: "Funt / fut / mil ", isChecked: false, id: '1'),
    Selection(name: "km / sm / kg ", isChecked: true, id: '2'),
  ];
}
