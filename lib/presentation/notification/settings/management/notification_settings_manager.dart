// notification_settings_manager.dart
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class NotificationSettingsManager
    extends Manager<NotificationSettingsState, NotificationSettingsEffect> {
  final NotificationRepo _notificationRepo;

  NotificationSettingsManager(this._notificationRepo) : super(NotificationSettingsState());

  void getNotificationSettings() async {
    await _notificationRepo.getNotificationSettings().handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) => emit(state.copyWith(notificationSettings: data, loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }

  void getReminders() async {
    await _notificationRepo.getReminders().handle(
      onStart: () => emit(state.copyWith(loading: true)),
      onData: (data) => emit(state.copyWith(reminders: data, loading: false)),
      onDone: () => emit(state.copyWith(loading: false)),
    );
  }

  void postNotificationSettings({
    required String menu,
    required String time,
    required String type,
  }) async {
    await _notificationRepo
        .postNotificationSettings(ReminderRequest(time: time, type: type, menu: menu))
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (_) {
            getReminders();
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  void deleteNotificationSetting(int id) async {
    await _notificationRepo
        .deleteNotificationSetting(id)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (_) {
            getReminders();
          },
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  void saveSettings() {
    getReminders();
  }
}
