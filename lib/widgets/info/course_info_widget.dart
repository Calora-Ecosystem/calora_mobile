import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CourseInfoWidget extends StatelessWidget {
  final String description;

  const CourseInfoWidget({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Strings.briefInformation.text(16, 20, 500).c(context.colors.textStrong),
          const SizedBox(height: 12),
          description.text(14, 16, 400).c(context.colors.textStrong),
        ],
      ),
    );
  }
}
