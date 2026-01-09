import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/selection/Selection.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SingleSelectionItemBuilder extends StatelessWidget {
  final Selection selection;
  final Function(Selection) onClicked;

  SingleSelectionItemBuilder({
    super.key,
    required this.selection,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => selection.isChecked ? null : onClicked(selection),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            selection.isHaveIcon
                ? SvgPicture.asset(selection.icon)
                : const SizedBox(),
            SizedBox(width: 4),
            Expanded(
              child: selection.name
                  .text(14, 16, 400)
                  .c(context.colors.textPrimary),
            ),
            SizedBox(width: 12),
            selection.isChecked
                ? Assets.icons.icSingleCheck.svg()
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
