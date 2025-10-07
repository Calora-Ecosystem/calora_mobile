import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/video_player/full_screen_video_player.dart';
import 'package:calora/common/widgets/video_player/management/video_management.dart';
import 'package:calora/common/widgets/video_player/management/video_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends Managed<VideoManager, VideoState, VideoEffect> {
  final String videoUrl;

  const VideoPlayerPage({@pathParam required this.videoUrl, super.key});

  @override
  void init(BuildContext context, VideoManager manager) {
    manager.initializeVideo(videoUrl);
  }

  @override
  void listener(BuildContext context, VideoManager manager, VideoEffect effect) {
    effect.when(
      showError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $message')));
      },
      openFullscreen: () {
        if (manager.controller != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullscreenVideoPlayer(controller: manager.controller!),
            ),
          );
        }
      },
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
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final videoController = state.controller;
    if (videoController == null || !videoController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: state.aspectRatio,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text("Error: Video not initialized")),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
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
                                  icon: Assets.icons.start.svg(),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                                          padding: const EdgeInsets.symmetric(vertical: 4),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('VideoPlayerPage dispose called');
    super.dispose();
  }
}
