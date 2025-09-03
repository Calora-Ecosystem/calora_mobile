
import 'package:calora/presentation/questions/name/management/input_name_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class InputNameManager extends Manager<InputNameState, InputNameEffect> {
  InputNameManager() : super(const InputNameState());

}
