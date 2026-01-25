import 'package:calora/domain/model/notification/notification.dart' as model;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

part 'inbox_management.freezed.dart';

@freezed
abstract class InboxState with _$InboxState {
  const factory InboxState({
    PagingController<int, model.Notification>? notificationController,
  }) = _InboxState;
}

@freezed
abstract class InboxEffect with _$InboxEffect {
  const factory InboxEffect() = _InboxEffect;
}
