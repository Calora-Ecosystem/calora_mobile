import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

import 'package:calora/common/gen/assets.gen.dart';

class GenderWidget extends StatefulWidget {
  final Function(Gender)? onGenderSelected;

  const GenderWidget({super.key, this.onGenderSelected});

  @override
  State<GenderWidget> createState() => _GenderWidgetState();
}

class _GenderWidgetState extends State<GenderWidget> {
  Gender? selected;

  void _selectGender(Gender gender) {
    setState(() {
      selected = gender;
    });
    widget.onGenderSelected?.call(gender);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        genderButton(
          gender: Gender.Male,
          icon: Assets.icons.male.svg(),
          label: Strings.male,
          borderColor: context.colors.neutral600Secondary,
        ),
        const SizedBox(width: 8),
        genderButton(
          gender: Gender.Female,
          icon: Assets.icons.female.svg(),
          label: Strings.female,
          borderColor: context.colors.neutral600Secondary,
        ),
      ],
    );
  }

  Widget genderButton({
    required Gender gender,
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
            border: Border.all(color: isSelected ? borderColor : Colors.transparent),
            color: context.colors.commonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(child: label.text(14, 18, 500)),
            ],
          ),
        ),
      ),
    );
  }
}
