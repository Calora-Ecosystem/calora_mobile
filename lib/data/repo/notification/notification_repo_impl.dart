import 'package:calora/data/api/notification_api.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

@Injectable(as: NotificationRepo)
class NotificationRepoImpl extends NotificationRepo {
  final ProfileApi profileApi;
  final NotificationApi notificationApi;
  static const int _pageSize = 20;
  final BehaviorSubject<int> _unreadCountSubject = BehaviorSubject<int>.seeded(
    0,
  );

  NotificationRepoImpl(this.profileApi, this.notificationApi);

  @override
  Future<List<ReminderRequest>> getReminders() async {
    return await notificationApi.getReminders();
  }

  @override
  Future<ReminderRequest> updateReminder(ReminderRequest request) async {
    return await notificationApi.updateReminder(request);
  }

  @override
  Future<void> deleteReminder(int id) async {
    await notificationApi.deleteReminder(id);
  }

  PagingController<int, model.Notification> getNotifications() {
    const int _keepLast = 10;

    final controller = PagingController<int, model.Notification>(
      firstPageKey: 0,
    );

    controller.addPageRequestListener((pageKey) async {
      try {
        final response = await notificationApi.getNotifications(
          skip: pageKey,
          take: _pageSize,
        );

        final data = response.data as Map<String, dynamic>;
        final List<dynamic> content = data['content'] ?? [];
        final notifications = content.map((e) => model.Notification.fromJson(e as Map<String, dynamic>)).toList();

        final isLastPage = notifications.length < _pageSize;

        if (isLastPage) {
          controller.appendLastPage(notifications);
        } else {
          final nextPageKey = pageKey + notifications.length;
          controller.appendPage(notifications, nextPageKey);
        }

        final list = controller.itemList ?? <model.Notification>[];
        if (list.length > _keepLast) {
          controller.itemList = list.sublist(list.length - _keepLast);
          controller.notifyListeners();
        }
      } catch (error) {
        controller.error = error;
      }
    });

    return controller;
  }

  @override
  Stream<int> getUnread() {
    notificationApi
        .getUnread()
        .then((response) {
          final data = response.data as Map<String, dynamic>;
          _unreadCountSubject.add(data['content']);
        })
        .catchError((_) {});
    return _unreadCountSubject.stream;
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    await notificationApi.markAsRead(notificationId);
    if (_unreadCountSubject.value > 0) {
      _unreadCountSubject.add(_unreadCountSubject.value - 1);
    }
  }
}
