import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/painter/dashed_border_painter.dart';
import 'package:calora/presentation/ai/camera/management/camera_management.dart';
import 'package:calora/presentation/ai/camera/management/camera_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CaloraCameraPage extends Managed<CameraManager, CameraState, CameraEffect> {
  const CaloraCameraPage({super.key});

  @override
  void init(BuildContext context, CameraManager manager) {
    manager.initCamera();
  }

  @override
  void listener(BuildContext context, CameraManager manager, CameraEffect effect) {
    effect.when(
      photoTaken: (path) {
        Future.microtask(() {
          if (context.mounted) {
            context.router.replace(CaloraAiCalculateRoute(imagePath: path));
          }
        });
      },
    );
  }

  @override
  Widget builder(BuildContext context, CameraManager manager, CameraState state) {
    final controller = manager.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),

          Column(
            children: [
              Container(
                width: double.infinity,
                color: context.colors.backgroundElevation6.withAlpha(72),
                padding: const EdgeInsets.only(top: 60, left: 20, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Strings.caloraAi.text(30, 38, 700).c(context.colors.white),
                    const SizedBox(height: 8),
                    Strings.turnYourFaceToThisSquare.text(14, 20, 400).c(context.colors.white),
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
                      child: Container(width: 20, color: context.colors.backgroundElevation6.withAlpha(72)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 20, color: context.colors.backgroundElevation6.withAlpha(72)),
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

              // Pastdagi capture tugmasi
              Container(
                width: double.infinity,
                color: context.colors.backgroundElevation6.withAlpha(72),
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: context.colors.white)),
                      ),
                      child: Strings.caloraAi.text(16, 20, 500).c(context.colors.white),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: state.isLoading || !state.isReady ? null : manager.takePicture,
                      child: Opacity(
                        opacity: state.isLoading || !state.isReady ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.white, width: 1),
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: state.isLoading
                                  ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                  : null,
                            ),
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
