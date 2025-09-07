import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

import '../../../common/gen/assets.gen.dart';

class Gender extends StatefulWidget {
  final ValueChanged<String>? onGenderSelected;

  const Gender({super.key, this.onGenderSelected});

  @override
  State<Gender> createState() => _GenderState();
}

class _GenderState extends State<Gender> {
  String? selected;

  void _selectGender(String gender) {
    setState(() {
      selected = gender;
    });
    if (widget.onGenderSelected != null) {
      widget.onGenderSelected!(gender);
    }
  }

  Widget genderButton({
    required String gender,
    required Widget icon,
    required String label,
    required Color borderColor,
  }) {
    final isSelected = selected == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectGender(gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? borderColor : Colors.transparent, width: 1),
            color: context.colors.commonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [icon, const SizedBox(width: 8), label.text(14, 18, 500)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        genderButton(
          gender: "male",
          icon: Assets.icons.male.svg(),
          label: Strings.male,
          borderColor: context.colors.strokeAccent,
        ),
        const SizedBox(width: 8),
        genderButton(
          gender: "female",
          icon: Assets.icons.female.svg(),
          label: Strings.famale,
          borderColor: context.colors.strokeAccent,
        ),
      ],
    );
  }
}
