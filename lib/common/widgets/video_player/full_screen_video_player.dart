import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _setLandscapeMode();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _setLandscapeMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullScreenMode() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _exitFullScreenMode();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void _skipForward() {
    final current = widget.controller.value.position;
    final target = current + const Duration(seconds: 10);
    widget.controller.seekTo(target);
  }

  void _skipBackward() {
    final current = widget.controller.value.position;
    final target = current - const Duration(seconds: 10);
    widget.controller.seekTo(target);
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _isControlsVisible = !_isControlsVisible),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),
              if (_isControlsVisible) _buildControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Assets.icons.minimizeScreen.svg(),
                onPressed: () {
                  _exitFullScreenMode();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Assets.icons.replay10.svg(), onPressed: _skipBackward),
              const SizedBox(width: 50),
              IconButton(icon: Assets.icons.start.svg(), onPressed: _togglePlayPause),
              const SizedBox(width: 50),
              IconButton(icon: Assets.icons.forward10.svg(), onPressed: _skipForward),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  _format(widget.controller.value.position).text(14, 16, 400).c(Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VideoProgressIndicator(
                      widget.controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.blue,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _format(widget.controller.value.duration).text(14, 16, 400).c(Colors.white),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
