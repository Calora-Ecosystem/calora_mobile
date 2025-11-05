import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_management.freezed.dart';

@freezed
abstract class CameraState with _$CameraState {
  const factory CameraState({@Default(false) bool isLoading, @Default(false) bool isReady, String? imagePath}) =
      _CameraState;
}

@freezed
abstract class CameraEffect with _$CameraEffect {
  const factory CameraEffect.photoTaken(String path) = _PhotoTaken;
}
