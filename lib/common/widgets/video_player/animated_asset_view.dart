import 'package:cached_network_image/cached_network_image.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/video_player/looping_muted_video_player.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Renders an exercise preview asset, branching by file extension:
///
/// * `.gif` → `CachedNetworkImage` (Flutter animates GIFs natively, no
///   video decoder needed — cheap to mount, no per-card controllers
///   to manage).
/// * anything else (`.mp4`, `.mov`, `.webm`, …) →
///   [LoopingMutedVideoPlayer], which manages its own controller
///   lifecycle and disposes when scrolled past the lazy list's
///   `cacheExtent`.
///
/// Use this anywhere the backend's `Default` asset is consumed —
/// historically the API has sent both MP4s (`videos/X.mp4`) and GIFs
/// (`images/X.gif`) in that slot, so call sites can't assume one
/// format.
class AnimatedAssetView extends StatelessWidget {
  /// Already-resolved absolute URL (i.e. the value of
  /// `ExercisesRequestX.previewAssetUrl`, which prepends the file-
  /// server base for relative paths). Pass `null` to render the
  /// fallback icon.
  final String? url;

  /// Logical height of the playback area.
  final double height;

  /// Corner radius for the clip mask.
  final double borderRadius;

  /// Set for a single prominent preview so it can claim a video decoder
  /// from the list thumbnails mounted behind it. See
  /// [LoopingMutedVideoPlayer.priority]. Leave false for per-row use.
  final bool priority;

  const AnimatedAssetView({
    super.key,
    required this.url,
    this.height = 120,
    this.borderRadius = 16,
    this.priority = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim();
    if (resolved == null || resolved.isEmpty) {
      return _ErrorBox(height: height, borderRadius: borderRadius);
    }

    if (_isGifUrl(resolved)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: resolved,
            fit: BoxFit.cover,
            placeholder: (_, __) => _Placeholder(height: height),
            errorWidget: (_, __, ___) =>
                _ErrorBox(height: height, borderRadius: borderRadius),
          ),
        ),
      );
    }

    return LoopingMutedVideoPlayer(
      url: resolved,
      height: height,
      borderRadius: borderRadius,
      priority: priority,
    );
  }

  /// Inspects the path component for a `.gif` extension. Strips
  /// query strings and URL fragments first so trailing
  /// `?cb=123` / `#anchor` don't break detection.
  static bool _isGifUrl(String url) {
    final path = url.split('?').first.split('#').first.toLowerCase();
    return path.endsWith('.gif');
  }
}

class _Placeholder extends StatelessWidget {
  final double height;

  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      loading: true,
      type: ShimmerType.backgroundElevation,
      shimmerChild: ShimmerChild(height: height),
      child: const SizedBox.shrink(),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _ErrorBox({required this.height, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_filter_outlined,
        size: 32,
        color: context.colors.iconSoft,
      ),
    );
  }
}
