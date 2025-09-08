import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@Injectable()
class CalculateManager extends Manager<CalculateState, CalculateEffect> {
  CalculateManager() : super(CalculateState.initial());
}
