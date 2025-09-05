import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'calories_management.dart';

@injectable
class CaloriesManager extends Manager<CaloriesState, CaloriesEffect> {

  CaloriesManager() : super(const CaloriesState());

}