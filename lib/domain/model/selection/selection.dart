import 'package:calora/domain/model/selection/selection_type.dart';

class Selection {
  final String id;
  final String name;
  final String icon;
  final bool isChecked;
  final SelectionType type;

  Selection({
    this.id = "",
    this.name = "",
    this.icon = "",
    this.isChecked = false,
    this.type = SelectionType.none,
  });

  bool get isHaveIcon => icon.isNotEmpty;

  Selection copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isChecked,
    SelectionType? type,
  }) {
    return Selection(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isChecked: isChecked ?? this.isChecked,
      type: type ?? this.type,
    );
  }
}
