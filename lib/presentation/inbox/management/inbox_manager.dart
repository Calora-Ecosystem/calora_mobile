import 'package:calora/presentation/inbox/management/inbox_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class InboxManager extends Manager<InboxState, InboxEffect> {
  InboxManager() : super(InboxState());
}
