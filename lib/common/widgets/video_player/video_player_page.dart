import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/video_player/full_screen_video_player.dart';
import 'package:calora/common/widgets/video_player/management/video_management.dart';
import 'package:calora/common/widgets/video_player/management/video_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends Managed<VideoManager, VideoState, VideoEffect> {
  final String videoUrl;
  final VoidCallback? onVideoComplete;

  const VideoPlayerPage({
    @pathParam required this.videoUrl,
    this.onVideoComplete,
    super.key,
  });

  @override
  void init(BuildContext context, VideoManager manager) {
    manager.setOnVideoCompleteListener(onVideoComplete);
    manager.initializeVideo(videoUrl);
  }

  @override
  void listener(
    BuildContext context,
    VideoManager manager,
    VideoEffect effect,
  ) {
    effect.when(
      showError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Strings.errorLabel}: $message')),
        );
      },
      openFullscreen: () {
        if (manager.controller != null) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => FullscreenVideoPlayer(controller: manager.controller!),
            ),
          );
        }
      },
      videoCompleted: () {},
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget builder(BuildContext context, VideoManager manager, VideoState state) {
    if (!state.isInitialized) {
      Widget content;
      Color backgroundColor;

      if (state.errorMessage != null) {
        content = Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${Strings.errorLabel}: ${state.errorMessage}',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
        backgroundColor = Colors.black;
      } else {
        content = const CircularProgressIndicator();
        backgroundColor = context.colors.backgroundElevation;
      }

      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        child: Center(child: content),
      );
    }

    final videoController = state.controller!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: manager.toggleControls,
        child: AspectRatio(
          aspectRatio: state.aspectRatio,
          child: Stack(
            children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: videoController.value.size.width,
                    height: videoController.value.size.height,
                    child: VideoPlayer(videoController),
                  ),
                ),
              ),
              if (state.isControlsVisible)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black54,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Assets.icons.fullScreen.svg(),
                          onPressed: manager.openFullscreen,
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Assets.icons.replay10.svg(),
                              onPressed: manager.skipBackward,
                            ),
                            IconButton(
                              icon: state.isPlaying
                                  ? Assets.icons.icPause.svg()
                                  : Assets.icons.start.svg(),
                              onPressed: manager.togglePlayPause,
                            ),
                            IconButton(
                              icon: Assets.icons.forward10.svg(),
                              onPressed: manager.skipForward,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Row(
                                children: [
                                  _formatDuration(
                                    state.position,
                                  ).text(12, 16, 400).c(context.colors.textWhite),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: VideoProgressIndicator(
                                      videoController,
                                      allowScrubbing: true,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.blue,
                                        bufferedColor: Colors.white38,
                                        backgroundColor: Colors.white24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _formatDuration(
                                    state.duration,
                                  ).text(12, 16, 400).c(context.colors.textWhite),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
