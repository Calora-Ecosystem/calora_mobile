import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/inbox/management/inbox_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class InboxManager extends Manager<InboxState, InboxEffect> {
  final NotificationRepo _notificationRepo;

  InboxManager(this._notificationRepo) : super(InboxState());

  void initializeNotifications() {
    final controller = _notificationRepo.getNotifications();
    emit(state.copyWith(notificationController: controller));
  }

  @override
  Future<void> close() {
    state.notificationController?.dispose();
    return super.close();
  }
}
