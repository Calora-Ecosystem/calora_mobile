import 'package:calora/domain/model/selection/Selection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'single_selection_management.freezed.dart';

@freezed
abstract class SingleSelectionState with _$SingleSelectionState {
  const factory SingleSelectionState({
    @Default(false) bool loading,
    @Default([]) List<Selection> selections,
  }) = _SingleSelectionState;
}

@freezed
sealed class SingleSelectionEffect with _$SingleSelectionEffect {
  const factory SingleSelectionEffect() = _SingleSelectionEffect;
}
