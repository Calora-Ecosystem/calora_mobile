import 'dart:async';
import 'dart:ui';

import 'package:calora/common/widgets/video_player/management/video_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:video_player/video_player.dart';

@injectable
class VideoManager extends Manager<VideoState, VideoEffect> {
  VideoPlayerController? _controller;
  Timer? _controlsTimer;

  VoidCallback? _onVideoComplete;
  bool _hasCalledOnComplete = false; // Flag to prevent multiple calls

  VideoManager() : super(const VideoState());

  void setOnVideoCompleteListener(VoidCallback? listener) {
    _onVideoComplete = listener;
  }

  Future<void> initializeVideo(String videoUrl) async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }

      // Reset the flag when initializing a new video
      _hasCalledOnComplete = false;

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _controller!.initialize();

      emit(
        state.copyWith(
          isInitialized: true,
          controller: _controller,
          duration: _controller!.value.duration,
          aspectRatio: _controller!.value.aspectRatio,
          isControlsVisible: true,
        ),
      );

      _controller!.addListener(_onVideoUpdate);

      await _controller!.play();
      emit(state.copyWith(isPlaying: true));

      _startHideControlsTimer();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      publish(VideoEffect.showError(e.toString()));
    }
  }

  void _onVideoUpdate() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final value = _controller!.value;
    final currentPosition = value.position;
    final videoDuration = value.duration;

    emit(
      state.copyWith(
        position: currentPosition,
        duration: videoDuration,
        isPlaying: value.isPlaying,
      ),
    );

    // Check if video is 2 seconds away from completion
    if (!_hasCalledOnComplete &&
        videoDuration != Duration.zero &&
        videoDuration.inSeconds > 0) {
      final remainingSeconds = (videoDuration - currentPosition).inSeconds;

      if (remainingSeconds <= 2 && remainingSeconds >= 0) {
        _hasCalledOnComplete = true;

        print('Video completing: remaining $remainingSeconds seconds');
        print('onVideoComplete callback is null: ${_onVideoComplete == null}');

        // Call the onVideoComplete callback immediately
        if (_onVideoComplete != null) {
          print('Calling onVideoComplete callback now!');
          _onVideoComplete!();
        } else {
          print('Warning: onVideoComplete callback is null!');
        }

        publish(const VideoEffect.videoCompleted());

        emit(state.copyWith(isCompleted: true));
      }
    }
  }

  void togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }

    emit(state.copyWith(isPlaying: _controller!.value.isPlaying));
    _startHideControlsTimer();
  }

  void toggleControls() {
    emit(state.copyWith(isControlsVisible: !state.isControlsVisible));

    if (state.isControlsVisible) {
      _startHideControlsTimer();
    } else {
      _cancelHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (state.isControlsVisible &&
          _controller != null &&
          _controller!.value.isPlaying) {
        emit(state.copyWith(isControlsVisible: false));
      }
    });
  }

  void _cancelHideControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = null;
  }

  void skipForward() {
    if (_controller == null) return;
    final newPosition = state.position + const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
    emit(state.copyWith(position: newPosition));
    _startHideControlsTimer();
  }

  void skipBackward() {
    if (_controller == null) return;
    final newPosition = state.position - const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
    emit(state.copyWith(position: newPosition));
    _startHideControlsTimer();
  }

  void seekTo(Duration position) {
    if (_controller == null) return;
    _controller!.seekTo(position);
    emit(state.copyWith(position: position));
    _startHideControlsTimer();
  }

  void openFullscreen() {
    publish(const VideoEffect.openFullscreen());
  }

  VideoPlayerController? get controller => _controller;

  @override
  Future<void> close() async {
    _cancelHideControlsTimer();
    _controller?.removeListener(_onVideoUpdate);
    await _controller?.dispose();
    _controller = null;
    _hasCalledOnComplete = false;
    emit(const VideoState(aspectRatio: 1.0, isControlsVisible: true));
    await super.close();
  }
}
