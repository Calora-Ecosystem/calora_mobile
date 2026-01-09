import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class QuestionWidget extends StatelessWidget {
  final String questionText;
  final Widget child;
  final Widget icon;

  const QuestionWidget({
    super.key,
    required this.questionText,
    required this.child,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.backgroundBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: questionText
                    .text(14, 18, 400)
                    .c(context.colors.textStrong)
                    .copyWith(
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
