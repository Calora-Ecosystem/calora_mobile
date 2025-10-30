import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CaloraCameraPage extends StatefulWidget {
  const CaloraCameraPage({super.key});

  @override
  State<CaloraCameraPage> createState() => _CaloraCameraPageState();
}

class _CaloraCameraPageState extends State<CaloraCameraPage> {
  CameraController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(front, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!_controller!.value.isInitialized) return;
    final image = await _controller!.takePicture();
    debugPrint("Photo path: ${image.path}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller!),

          // Ramka
          Container(
            width: 250,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // Yuqoridagi textlar
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Calora AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Yuzingizni ushbu maydonga to‘g‘irlang!",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Pastdagi tugma
          Positioned(
            bottom: 50,
            child: Column(
              children: [
                const Text(
                  "Calora AI",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
