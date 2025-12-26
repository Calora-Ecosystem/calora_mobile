import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/selection/Selection.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/selection/single/management/single_selection_management.dart';
import 'package:calora/presentation/selection/single/management/single_selection_manager.dart';
import 'package:calora/widgets/builder/selection/single/single_selection_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class SingleSelectionPage extends Managed<SingleSelectionManager, SingleSelectionState, SingleSelectionEffect> {
  final Selection selection;
  final Function(Selection) onSave;
  final String title;
  final String? initialSelectedValue;
  final bool loading;

  SingleSelectionPage({
    super.key,
    this.title = '',
    required this.selection,
    required this.onSave,
    this.initialSelectedValue,
    this.loading = false,
  });

  @override
  void init(context, manager) {
    manager.setSelection(selection, initialSelectedValue: initialSelectedValue);
    manager.getSelections();
  }

  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(height: 2, width: 24, color: context.colors.strokeSub)),
          const SizedBox(height: 8),
          if (title.isNotEmpty) ...[
            title.text(20, 24, 700).c(context.colors.textStrong),
            const SizedBox(height: 12),
          ],
          ListView.builder(
            shrinkWrap: true,
            itemCount: state.selections.length,
            itemBuilder: (context, index) {
              final currentSelection = state.selections[index];
              return SingleSelectionItemBuilder(
                selection: currentSelection,
                onClicked: (data) => manager.updateSelectionItem(data),
              );
            },
          ),
          const SizedBox(height: 16),
          Button(
            loading: loading,
            text: Strings.save,
            onPressed: () => onSave(manager.getSelectedItem() ?? Selection()),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
