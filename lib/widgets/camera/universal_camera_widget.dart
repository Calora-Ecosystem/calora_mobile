import 'package:auto_route/auto_route.dart';
import 'package:calora/common/widgets/painter/dashed_border_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

@RoutePage()
class UniversalCameraPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String bottomText;
  final bool useFrontCamera;
  final Future<void> Function(String image)? onImageCaptured;

  const UniversalCameraPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bottomText,
    required this.onImageCaptured,
    this.useFrontCamera = true,
  });

  @override
  State<UniversalCameraPage> createState() => _UniversalCameraPageState();
}

class _UniversalCameraPageState extends State<UniversalCameraPage> {
  CameraController? _controller;
  bool isLoading = true;
  bool isReady = false;
  bool isTaking = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final selectedCamera = widget.useFrontCamera
        ? cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          )
        : cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isReady = true;
    });
  }

  Future<void> _takePhoto() async {
    if (!isReady || isTaking || _controller == null) return;
    setState(() => isTaking = true);
    try {
      final XFile file = await _controller!.takePicture();
      await widget.onImageCaptured?.call(file.path);
    } catch (e) {
      debugPrint('Foto olishda xatolik: $e');
    } finally {
      setState(() => isTaking = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize?.height ?? 1,
                height: _controller!.value.previewSize?.width ?? 1,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 20, bottom: 12),
                color: Colors.black.withAlpha(72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        color: Colors.black.withAlpha(72),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        color: Colors.black.withAlpha(72),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 0,
                      bottom: 0,
                      child: CustomPaint(painter: DashedBorderPainter()),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 50),
                color: Colors.black.withAlpha(72),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white)),
                      ),
                      child: Text(
                        widget.bottomText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: isTaking ? null : _takePhoto,
                      child: Opacity(
                        opacity: isTaking ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: isTaking
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
