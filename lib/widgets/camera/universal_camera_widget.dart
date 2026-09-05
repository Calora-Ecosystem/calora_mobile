import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/painter/dashed_border_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

@RoutePage()
class UniversalCameraPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String bottomText;
  final bool useFrontCamera;

  /// Whether to offer picking an existing photo from the gallery next to the
  /// shutter. Enabled for food scanning (a photo of a past meal works just as
  /// well as a live shot); left off for flows that need a live capture, such
  /// as the face scan.
  final bool allowGallery;
  final Future<void> Function(String image)? onImageCaptured;

  const UniversalCameraPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bottomText,
    required this.onImageCaptured,
    this.useFrontCamera = true,
    this.allowGallery = false,
  });

  @override
  State<UniversalCameraPage> createState() => _UniversalCameraPageState();
}

/// Why the camera could not be opened. Drives which recovery action the
/// error state offers.
enum _CameraError { permissionDenied, permissionPermanentlyDenied, unavailable }

class _UniversalCameraPageState extends State<UniversalCameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool isLoading = true;
  bool isReady = false;
  bool isTaking = false;
  _CameraError? _error;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    // Coming back from the system settings page: the user may have just
    // granted access, so try again instead of leaving them on the error
    // screen.
    if (!isReady && !isLoading) _initCamera();
  }

  /// Initializes the preview, turning *every* failure into a visible state.
  /// A thrown [availableCameras] / [CameraController.initialize] used to
  /// leave `isLoading` stuck at true, which showed an endless spinner on a
  /// black screen with no way back.
  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      isReady = false;
      _error = null;
    });

    // Release a controller left over from a previous failed attempt before
    // creating a new one.
    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    if (!status.isGranted) {
      _failWith(
        status.isPermanentlyDenied || status.isRestricted
            ? _CameraError.permissionPermanentlyDenied
            : _CameraError.permissionDenied,
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _failWith(_CameraError.unavailable);
        return;
      }

      final selectedCamera = widget.useFrontCamera
          ? cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      setState(() {
        isLoading = false;
        isReady = true;
      });
    } on CameraException catch (e, s) {
      debugPrint('Camera init failed: ${e.code} ${e.description}\n$s');
      _failWith(
        // iOS/Android report a denied or restricted permission through the
        // plugin as well when the OS-level check above raced with a change.
        e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt' || e.code == 'CameraAccessRestricted'
            ? _CameraError.permissionPermanentlyDenied
            : _CameraError.unavailable,
      );
    } catch (e, s) {
      debugPrint('Camera init failed: $e\n$s');
      _failWith(_CameraError.unavailable);
    }
  }

  void _failWith(_CameraError error) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      isReady = false;
      _error = error;
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
      // onImageCaptured usually pops this route, so the state may be gone.
      if (mounted) setState(() => isTaking = false);
    }
  }

  /// Lets the user hand an existing photo to the same pipeline as a live
  /// capture. Uses the system photo picker, which needs no gallery permission
  /// on modern Android/iOS, so it works even though the app deliberately drops
  /// the media-read permissions.
  Future<void> _pickFromGallery() async {
    if (isTaking) return;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;
      setState(() => isTaking = true);
      await widget.onImageCaptured?.call(file.path);
    } catch (e) {
      debugPrint('Galereyadan rasm tanlashda xatolik: $e');
    } finally {
      // onImageCaptured usually pops this route, so the state may be gone.
      if (mounted) setState(() => isTaking = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Translucent circular control used for the overlay back button. Kept in
  /// the camera's white-on-dark language so it reads on any preview frame.
  Widget _overlayCircleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white.withAlpha(38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  /// The capture shutter, extracted so the bottom bar can center it while the
  /// gallery button sits to its side.
  Widget _shutterButton() {
    return GestureDetector(
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
    );
  }

  /// Rounded, translucent tile that opens the system photo picker, echoing the
  /// shutter's white-on-dark styling so the two controls read as a set. Icon
  /// only, so it needs no new localized label to stay clear in every language.
  Widget _galleryButton() {
    return GestureDetector(
      onTap: isTaking ? null : _pickFromGallery,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(140), width: 1.5),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Black full-screen shell with a back button, so a stuck or failed camera
  /// never traps the user on a dead screen.
  Widget _blackScaffold(Widget body) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: 48,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.router.maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, _CameraError error) {
    final isPermission = error != _CameraError.unavailable;
    final message = isPermission ? Strings.allowAccessToYourCamera : Strings.errorViewMessage;
    final actionText = error == _CameraError.permissionPermanentlyDenied ? Strings.goToSettings : Strings.tryAgain;

    return _blackScaffold(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermission ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (error == _CameraError.permissionPermanentlyDenied) {
                  openAppSettings();
                } else {
                  _initCamera();
                }
              },
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildErrorScaffold(context, _error!);

    if (isLoading || _controller == null || !_controller!.value.isInitialized) {
      return _blackScaffold(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 20,
                  right: 20,
                  bottom: 12,
                ),
                color: Colors.black.withAlpha(72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _overlayCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.router.maybePop(),
                    ),
                    const SizedBox(height: 16),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Row(
                        children: [
                          // Left slot: gallery shortcut when allowed, otherwise
                          // an empty spacer so the shutter stays centered.
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: widget.allowGallery
                                  ? _galleryButton()
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          _shutterButton(),
                          // Right slot mirrors the left one to keep the shutter
                          // optically centered.
                          const Expanded(child: SizedBox.shrink()),
                        ],
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
