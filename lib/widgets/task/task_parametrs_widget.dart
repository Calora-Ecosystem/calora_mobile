import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class TaskParametersWidget extends StatelessWidget {
  final Widget title;
  final List<ParameterItem> parameters;
  final String? bottomLabel;
  final int? bottomCount;
  final VoidCallback? onChangePressed;

  const TaskParametersWidget({
    super.key,
    required this.title,
    required this.parameters,
    this.bottomLabel,
    this.bottomCount,
    this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(parameters.length, (index) {
            final item = parameters[index];
            final showDivider = index != parameters.length - 1;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildParameter(item, context),
                if (showDivider)
                  Container(
                    height: 28,
                    width: 1,
                    color: context.colors.neutral200Stroke,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
        if (bottomLabel != null || onChangePressed != null)
          Row(
            children: [
              if (bottomLabel != null)
                Row(
                  children: [
                    bottomLabel!.text(16, 20, 500),
                    if (bottomCount != null) ...[
                      const SizedBox(width: 4),
                      '(${bottomCount.toString()})'
                          .text(16, 20, 500)
                          .c(colors.neutral600Secondary),
                    ],
                  ],
                ),
              const Spacer(),
              if (onChangePressed != null)
                TextButton(
                  onPressed: onChangePressed,
                  child: Strings.change.text(14, 16, 600).c(colors.accentSub),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildParameter(ParameterItem item, BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item.value
            .text(16, 20, 500)
            .c(colors.neutral900Primary)
            .copyWith(overflow: TextOverflow.ellipsis),
        item.name
            .text(14, 18, 400)
            .c(colors.neutral600Secondary)
            .copyWith(overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class ParameterItem {
  final String name;
  final String value;

  const ParameterItem({required this.name, required this.value});
}
