import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {

  StepsManager() : super(const StepsState());

}