import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:video_player/video_player.dart';

part 'video_management.freezed.dart';

@freezed
abstract class VideoState with _$VideoState {
  const factory VideoState({
    @Default(false) bool isInitialized,
    @Default(false) bool isPlaying,
    @Default(false) bool isControlsVisible,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(0.5) double aspectRatio,
    VideoPlayerController? controller,
    String? errorMessage,
  }) = _VideoState;
}

@freezed
class VideoEffect with _$VideoEffect {
  const factory VideoEffect.showError(String message) = _ShowError;
  const factory VideoEffect.openFullscreen() = _OpenFullscreen;
}
