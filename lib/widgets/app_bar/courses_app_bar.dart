import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CoursesAppBar extends StatelessWidget {
  final String imageUrl;
  final void Function() openInfoSheet;

  const CoursesAppBar({super.key, required this.openInfoSheet, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.watch(),
      builder: (context, snapshot) {
        return SafeArea(
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: ClipRect(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 48));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
                        child: Assets.icons.arrowLeft.svg(),
                      ),
                    ),
                    GestureDetector(
                      onTap: openInfoSheet,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
                        child: Assets.icons.informationCircle.svg(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
