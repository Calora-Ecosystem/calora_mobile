import 'package:calora/presentation/ai/camera/management/camera_management.dart';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CameraManager extends Manager<CameraState, CameraEffect> {
  CameraManager() : super(const CameraState());

  CameraController? _controller;
  bool _isTakingPicture = false;

  Future<void> initCamera() async {
    if (_controller != null) return;

    emit(state.copyWith(isLoading: true));

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    emit(state.copyWith(isLoading: false, isReady: true));
  }

  Future<void> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPicture) return;

    _isTakingPicture = true;

    final file = await _controller!.takePicture();

    emit(state.copyWith(imagePath: file.path));
    publish(CameraEffect.photoTaken(file.path));

    _isTakingPicture = false;
  }

  CameraController? get controller => _controller;

  @override
  Future<void> close() async {
    await _controller?.dispose();
    _controller = null;
    return super.close();
  }
}
