import 'package:calora/domain/model/selection/Selection.dart';
import 'package:calora/domain/repo/selection/selection_repo.dart';
import 'package:calora/presentation/selection/single/management/single_selection_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class SingleSelectionManager extends Manager<SingleSelectionState, SingleSelectionEffect> {
  final SelectionRepo _selectionRepo;

  SingleSelectionManager(this._selectionRepo) : super(const SingleSelectionState());
  Selection _currentSelection = Selection();

  void setSelection(Selection value) {
    _currentSelection = value;
  }

  void getSelections() async {
    await _selectionRepo
        .getSelections(_currentSelection)
        .handle(
          onStart: () => emit(state.copyWith(loading: true)),
          onData: (data) => emit(state.copyWith(selections: data)),
          onDone: () => emit(state.copyWith(loading: false)),
        );
  }

  void updateSelectionItem(Selection value) {
    emit(
      state.copyWith(
        selections: state.selections
            .map(
              (element) => element.id == value.id
                  ? element.copyWith(isChecked: !element.isChecked)
                  : element.copyWith(isChecked: false),
            )
            .toList(),
      ),
    );
  }

  Selection? getSelectedItem() {
    try {
      return state.selections.firstWhere((element) => element.isChecked);
    } catch (e) {
      return null;
    }
  }
}
