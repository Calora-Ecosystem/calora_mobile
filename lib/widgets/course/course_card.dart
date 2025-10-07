import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final AssetGenImage image;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.onTap,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 0, 0),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(20, 24, 600),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      description
                          .text(16, 20, 500)
                          .c(context.colors.textSub)
                          .copyWith(maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: image.image(fit: BoxFit.contain)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
