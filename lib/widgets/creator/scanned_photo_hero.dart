import 'dart:io';

import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Hero preview of the photo the user just captured while scanning a dish.
/// Rendered from the local file so it appears instantly (no network
/// round-trip) on the scan-result sheets. Returns an empty box when no photo
/// is available (e.g. the voice flow) so callers can drop it in
/// unconditionally.
///
/// Uses [BoxFit.cover] so the photo fills the frame edge to edge — the dish
/// is shown partially (cropped) but cleanly, with no letterbox bars.
class ScannedPhotoHero extends StatelessWidget {
  final String? imagePath;
  final double height;

  const ScannedPhotoHero({super.key, required this.imagePath, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        file,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: double.infinity,
          color: context.colors.backgroundElevation,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: context.colors.textSub,
          ),
        ),
      ),
    );
  }
}
