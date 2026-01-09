import 'dart:developer';

import 'package:calora/common/enums/menu_type_enum.dart';
import 'package:calora/common/enums/notification_setting_type.dart';
import 'package:calora/common/enums/reminder_types_enum.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@lazySingleton
class NotificationSettingsManager
    extends Manager<NotificationSettingsState, NotificationSettingsEffect> {
  final NotificationRepo _notificationRepo;

  NotificationSettingsManager(this._notificationRepo)
    : super(const NotificationSettingsState()) {
    getReminders();
  }

  Future<void> getReminders() async =>
      await _notificationRepo.getReminders().handle(
        onStart: () => emit(state.copyWith(loading: true)),
        onData: (data) {
          final Map<ReminderTypesEnum, ReminderRequest> newRemindersMap = {};
          for (final request in data) {
            if (request.type != null &&
                (request.menu != null ||
                    request.type == ReminderSettingTypeEnum.water.toApi)) {
              final settingType = ReminderSettingTypeEnum.fromApi(request.type);
              final menuType = MenuTypeEnum.fromApi(request.menu);
              final reminderType = ReminderTypesEnum.fromReminderSettings(
                menu: menuType,
                type: settingType,
              );
              if (reminderType != ReminderTypesEnum.none) {
                newRemindersMap[reminderType] = request;
              }
            }
          }
          log('REMOTE REMINDERS $newRemindersMap');
          emit(
            state.copyWith(
              remoteReminders: data,
              reminders: newRemindersMap,
              loading: false,
            ),
          );
        },
        onDone: () => emit(state.copyWith(loading: false)),
      );

  Future<void> _persistReminders(
    Iterable<ReminderRequest> remindersToPersist,
    List<Future<MapEntry<ReminderTypesEnum, ReminderRequest>>> updateFutures,
  ) async {
    final futures = <Future>[];

    for (final reminder in remindersToPersist) {
      String? formattedTime = reminder.time;
      if (formattedTime != null && formattedTime.length == 5) {
        formattedTime += ':00';
      }
      final requestToSend = reminder.copyWith(time: formattedTime);
      updateFutures.add(
        _notificationRepo.updateReminder(requestToSend).then((updatedReminder) {
          return MapEntry(
            _getReminderTypeFromRequest(updatedReminder),
            updatedReminder,
          );
        }),
      );
    }

    if (futures.isNotEmpty) await Future.wait(futures);
  }

  ReminderTypesEnum _getReminderTypeFromRequest(ReminderRequest request) {
    final settingType = ReminderSettingTypeEnum.fromApi(request.type);
    final menuType = MenuTypeEnum.fromApi(request.menu);
    return ReminderTypesEnum.fromReminderSettings(
      menu: menuType,
      type: settingType,
    );
  }

  Future<void> saveAllReminderChanges({
    required Map<ReminderTypesEnum, ReminderRequest> originalReminders,
  }) async {
    emit(state.copyWith(isSaving: true));

    final currentReminders = state.reminders;
    final List<Future<MapEntry<ReminderTypesEnum, ReminderRequest>>>
    updateFutures = [];
    final List<Future<ReminderTypesEnum>> deleteFutures = [];

    for (final entry in currentReminders.entries) {
      final key = entry.key;
      final currentReminder = entry.value;

      if (!originalReminders.containsKey(key) ||
          originalReminders[key] != currentReminder) {
        String? formattedTime = currentReminder.time;
        if (formattedTime != null && formattedTime.length == 5)
          formattedTime += ':00';
        final requestToSend = currentReminder.copyWith(time: formattedTime);
        updateFutures.add(
          _notificationRepo.updateReminder(requestToSend).then((
            updatedReminder,
          ) {
            return MapEntry(key, updatedReminder);
          }),
        );
      }
    }

    for (final entry in originalReminders.entries) {
      final key = entry.key;
      final originalReminder = entry.value;

      if (!currentReminders.containsKey(key)) {
        if (originalReminder.id != null) {
          deleteFutures.add(
            _notificationRepo
                .deleteReminder(originalReminder.id!)
                .then((_) => key),
          );
        }
      }
    }

    try {
      final List<MapEntry<ReminderTypesEnum, ReminderRequest>> updatedEntries =
          updateFutures.isNotEmpty ? await Future.wait(updateFutures) : [];
      final List<ReminderTypesEnum> deletedKeys = deleteFutures.isNotEmpty
          ? await Future.wait(deleteFutures)
          : [];

      final finalReminders = Map<ReminderTypesEnum, ReminderRequest>.from(
        currentReminders,
      );

      for (final entry in updatedEntries)
        finalReminders[entry.key] = entry.value;

      for (final key in deletedKeys) finalReminders.remove(key);

      emit(
        state.copyWith(
          reminders: finalReminders,
          remoteReminders: finalReminders.values.toList(),
        ),
      );
    } catch (e) {
      log('Error saving all reminders: $e');
      emit(state.copyWith(reminders: originalReminders));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> saveSingleReminderChange({
    required ReminderTypesEnum type,
    ReminderRequest? originalRequest,
  }) async {
    emit(state.copyWith(isSaving: true));

    final futures = <Future>[];
    final currentReminder = state.reminders[type];

    try {
      if (currentReminder != null) {
        if (originalRequest == null || originalRequest != currentReminder) {
          String? formattedTime = currentReminder.time;
          if (formattedTime != null && formattedTime.length == 5)
            formattedTime += ':00';

          final requestToSend = currentReminder.copyWith(time: formattedTime);
          futures.add(
            _notificationRepo.updateReminder(requestToSend).then((
              updatedReminder,
            ) {
              emit(
                state.copyWith(
                  reminders: {...state.reminders, type: updatedReminder},
                ),
              );
              return updatedReminder;
            }),
          );
        }
      } else {
        if (originalRequest != null && originalRequest.id != null) {
          futures.add(_notificationRepo.deleteReminder(originalRequest.id!));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    } catch (e) {
      log('Error saving single reminder: $e');
      if (originalRequest != null) {
        emit(
          state.copyWith(
            reminders: {...state.reminders, type: originalRequest},
          ),
        );
      } else {
        await getReminders();
      }
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  void updateReminder(ReminderTypesEnum type, ReminderRequest reminder) {
    emit(state.copyWith(reminders: {...state.reminders, type: reminder}));
    log(state.reminders.toString());
  }

  void removeReminder(ReminderTypesEnum type) {
    final newReminders = Map<ReminderTypesEnum, ReminderRequest>.from(
      state.reminders,
    );
    newReminders.remove(type);
    emit(state.copyWith(reminders: newReminders));
    log('REMOVED: ${state.reminders}');
  }

  void setReminders(Map<ReminderTypesEnum, ReminderRequest> newReminders) {
    emit(state.copyWith(reminders: newReminders));
  }
}
