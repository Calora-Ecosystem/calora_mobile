import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final CourseRequest course;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.onTap, required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            course.title.text(20, 24, 600),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        course.description
                            .text(16, 20, 500)
                            .c(context.colors.textSub)
                            .copyWith(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ],
                    ),
                  ),
                  if (course.assets != null)
                    CustomCachedNetworkImage.banner(
                      height: 120,
                      imageUrl: course.mainImage ?? '',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
