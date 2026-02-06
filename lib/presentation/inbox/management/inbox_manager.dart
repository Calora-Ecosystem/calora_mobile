import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/inbox/management/inbox_management.dart';
import 'package:injectable/injectable.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:management/management.dart';

@injectable
class InboxManager extends Manager<InboxState, InboxEffect> {
  final NotificationRepo _notificationRepo;

  late final PagingController<int, model.Notification> pagingController;

  InboxManager(this._notificationRepo) : super(InboxState()) {
    pagingController = _notificationRepo.getNotifications();

    pagingController.refresh();
  }

  void initializeNotifications() {}

  @override
  Future<void> close() {
    pagingController.dispose();
    return super.close();
  }
}
