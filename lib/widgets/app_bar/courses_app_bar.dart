import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
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
                  child: CustomCachedNetworkImage.banner(
                    imageUrl: imageUrl,
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
