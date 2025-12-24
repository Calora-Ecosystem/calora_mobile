import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:video_player/video_player.dart';

import 'package:calora/common/widgets/video_player/management/video_management.dart';

@injectable
class VideoManager extends Manager<VideoState, VideoEffect> {
  VideoPlayerController? _controller;
  Timer? _controlsTimer;

  VideoManager() : super(const VideoState());

  Future<void> initializeVideo(String videoUrl) async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }
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
    if (_controller != null && _controller!.value.isInitialized) {
      emit(
        state.copyWith(
          position: _controller!.value.position,
          duration: _controller!.value.duration,
          isPlaying: _controller!.value.isPlaying,
        ),
      );
    }
    if (_controller != null &&
        _controller!.value.duration != Duration.zero &&
        _controller!.value.position >= _controller!.value.duration &&
        _controller!.value.isPlaying) {
      emit(state.copyWith(isPlaying: false));
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
      if (state.isControlsVisible && _controller != null && _controller!.value.isPlaying) {
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
    emit(state.copyWith(position: newPosition)); // Holatni yangilash
    _startHideControlsTimer();
  }

  void skipBackward() {
    if (_controller == null) return;
    final newPosition = state.position - const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
    emit(state.copyWith(position: newPosition)); // Holatni yangilash
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
    print('VideoManager closed/disposed');

    emit(
      const VideoState(
        aspectRatio: 1.0,
        isControlsVisible: true,
      ),
    );
    await super.close();
  }
}
