import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_management.freezed.dart';

@freezed
class InboxState with _$InboxState {
  const factory InboxState() = _InboxState;
}

@freezed
class InboxEffect with _$InboxEffect {
  const factory InboxEffect() = _InboxEffect;
}
