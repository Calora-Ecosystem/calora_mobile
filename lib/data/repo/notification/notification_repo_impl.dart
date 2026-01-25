import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/api/notification_api.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification.dart' as model;
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/data/api/notification_api.dart';
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
  final BehaviorSubject<int> _unreadCountSubject = BehaviorSubject<int>.seeded(0);

  NotificationRepoImpl(this.profileApi, this.notificationApi);

  @override
  Future<List<NotificationSetting>> getNotificationSettings() {
    return Future.value(notifications);
  }

  List<NotificationSetting> notifications = [
    NotificationSetting(
      id: '1',
      title: Strings.mealReminders,
      type: NotificationSettingType.mealReminder,
      value: [Strings.before20Min, Strings.before20Min, Strings.before10Min],
    ),
    NotificationSetting(
      id: '2',
      title: Strings.remindersToDrinkWater,
      type: NotificationSettingType.waterReminder,
      value: [Strings.every3Hour],
    ),
    NotificationSetting(
      id: '3',
      title: Strings.sleepReminders,
      type: NotificationSettingType.sleepReminder,
      value: ['22:00'],
    ),
    NotificationSetting(
      id: '4',
      title: Strings.notesForThe30DayChallenge,
      type: NotificationSettingType.thirtyDayChallenges,
      value: ['22:00'],
    ),
  ];

  @override
  Future<List<ReminderRequest>> getReminders() async {
    return await _api.getReminders();
  }

  @override
  Future<ReminderRequest> updateReminder(ReminderRequest request) async {
    return await _api.updateReminder(request);
  }

  @override
  Future<void> deleteReminder(int id) async {
    await _api.deleteReminder(id);
  }

  @override
  PagingController<int, model.Notification> getNotifications() {
    final controller = PagingController<int, model.Notification>(firstPageKey: 0);

    controller.addPageRequestListener((pageKey) async {
      try {
        final notifications = List.generate(15, (i) => model.Notification(id: pageKey + i, userId: 1, title: 'Notification ${pageKey + i + 1}', description: 'This is notification number ${pageKey + i + 1}', hasRead: i % 3 != 0, sentAt: DateTime.now().subtract(Duration(hours: i)), image: i % 2 == 0 ? 'https://picsum.photos/200' : null)); // TODO DUMMY DATA - DELETE THIS LINE
        // final response = await notificationApi.getNotifications(skip: pageKey, take: _pageSize);
        // final List<dynamic> content = response.data['content'] ?? [];
        // final notifications = content.map((e) => model.Notification.fromJson(e as Map<String, dynamic>)).toList();

        final isLastPage = notifications.length < _pageSize;
        if (isLastPage) {
          controller.appendLastPage(notifications);
        } else {
          final nextPageKey = pageKey + notifications.length;
          controller.appendPage(notifications, nextPageKey);
        }
      } catch (error) {
        controller.error = error;
      }
    });

    return controller;
  }

  @override
  Stream<int> getUnread() {
    _unreadCountSubject.add(5); // TODO DUMMY DATA - DELETE THIS LINE
    // notificationApi.getUnread().then((response) {
    //   _unreadCountSubject.add(response.data['content']);
    // }).catchError((_) {});
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
