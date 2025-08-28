import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'verify_management.dart';

@injectable
class VerifyManager extends Manager<VerifyState, VerifyEffect> {
  VerifyManager() : super(const VerifyState());

}
