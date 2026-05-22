import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders an MP4 as a looping, muted, auto-playing "GIF".
///
/// Lifecycle
/// ─────────
/// * `initState`     — creates the controller, kicks off async init,
///                     mutes the volume, enables looping, and starts
///                     playback as soon as the first frame is ready.
/// * `didUpdateWidget` — if [url] changes, the old controller is
///                       disposed and a new one is created.
/// * `dispose`       — releases the controller. Standard lazy-list
///                     unmounting (e.g. when a card scrolls past the
///                     `cacheExtent`) calls this automatically, so we
///                     don't leak controllers off-screen.
///
/// While the controller is initializing the widget shows a shimmer
/// placeholder; on a load failure it falls back to a static icon so
/// the surrounding layout never collapses.
class LoopingMutedVideoPlayer extends StatefulWidget {
  /// Absolute URL of the source video. Pass `null` to render the
  /// fallback icon (e.g. when the asset is missing from the API
  /// payload).
  final String? url;

  /// Logical height of the playback area. The video is centered and
  /// covered (`BoxFit.cover`) so different aspect ratios crop rather
  /// than letterbox.
  final double height;

  /// Corner radius for the clip mask around the video.
  final double borderRadius;

  const LoopingMutedVideoPlayer({
    super.key,
    required this.url,
    this.height = 120,
    this.borderRadius = 16,
  });

  @override
  State<LoopingMutedVideoPlayer> createState() =>
      _LoopingMutedVideoPlayerState();
}

class _LoopingMutedVideoPlayerState extends State<LoopingMutedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController(widget.url);
  }

  @override
  void didUpdateWidget(covariant LoopingMutedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initController(widget.url);
    }
  }

  Future<void> _initController(String? url) async {
    if (url == null || url.isEmpty) {
      setState(() {
        _hasError = true;
        _controller = null;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() => _hasError = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.pause();
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final controller = _controller;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _hasError
            ? _ErrorFallback(height: widget.height)
            : (controller == null || !controller.value.isInitialized)
                ? _Placeholder(height: widget.height)
                : FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
      ),
    );
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

class _ErrorFallback extends StatelessWidget {
  final double height;

  const _ErrorFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: context.colors.backgroundElevation,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_filter_outlined,
        size: 32,
        color: context.colors.iconSoft,
      ),
    );
  }
}
