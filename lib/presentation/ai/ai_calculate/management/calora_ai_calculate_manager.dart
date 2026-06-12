import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/base_response/base_response.dart';
import 'package:calora/domain/model/face_analysis/face_analysis_model.dart';
import 'package:calora/domain/repo/ai/ai_repo.dart';
import 'package:calora/presentation/ai/ai_calculate/management/calora_ai_calculate_management.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

@injectable
class CaloraAiCalculateManager extends Manager<CaloraAiCalculateState, CaloraAiCalculateEffect> {
  final AiRepo _aiRepo;

  CaloraAiCalculateManager(this._aiRepo) : super(CaloraAiCalculateState.initial());

  Timer? _animationTimer;

  Future<void> analyzeFace(String filePath) async {
    emit(
      state.copyWith(
        isLoading: true,
        progressPercent: 0.0,
        errorMessage: null,
        isCompleted: false,
      ),
    );

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      final newProgress = (state.progressPercent + 0.01).clamp(0.0, 0.9);
      emit(state.copyWith(progressPercent: newProgress));
    });

    try {
      final BaseResponse<FaceAnalysisModel> response = await _aiRepo.analyzeFace(filePath);

      if (response.error != null || response.content == null) {
        _animationTimer?.cancel();
        final errorMessage = response.error ?? 'Face analysis failed.';
        emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
        publish(CaloraAiCalculateEffect.error(errorMessage));
        return;
      }

      _animationTimer?.cancel();
      _completeAnimation(response.content!);
    } catch (e) {
      _animationTimer?.cancel();
      final errorMessage = e is DioException
          ? 'Network error. Please check your connection.'
          : 'An unexpected error occurred.';
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage));
      publish(CaloraAiCalculateEffect.error(e.toString())); // For logging
    }
  }

  void _completeAnimation(FaceAnalysisModel result) {
    const double animationSpeed = 0.05;
    const int animationFramerate = 60;

    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 1000 ~/ animationFramerate),
      (timer) {
        final newProgress = (state.progressPercent + animationSpeed).clamp(
          0.0,
          1.0,
        );
        emit(state.copyWith(progressPercent: newProgress));

        if (newProgress >= 1.0) {
          timer.cancel();
          final items = _mapResultToAnalysisItems(result);
          emit(
            state.copyWith(
              isLoading: false,
              isCompleted: true,
              faceAnalysis: result,
              analysisItems: items,
              finalScore: result.healthPercent ?? 0,
            ),
          );
        }
      },
    );
  }

  List<AnalysisItem> _mapResultToAnalysisItems(FaceAnalysisModel model) {
    return [
      if (model.rashes != null)
        AnalysisItem(
          description: 'Yuzda toshmaalar bor - Jigarlangiz yoki oshqozoningizni tekshirting.',
          iconPath: Assets.icons.redUser.svg(),
          percentage: model.rashes!,
          status: 'Normal',
        ),
      if (model.darkEyes != null)
        AnalysisItem(
          description: "Ko'z osti qoraygan - Uyqu sifatini yaxshilang.",
          iconPath: Assets.icons.moon.svg(),
          percentage: model.darkEyes!,
          status: 'Normal',
        ),
      if (model.energy != null)
        AnalysisItem(
          description: "O'rtacha - Ko'proq suv iching va faol bo'ling.",
          iconPath: Assets.icons.energy.svg(),
          percentage: model.energy!,
          status: 'Normal',
        ),
      if (model.stress != null)
        AnalysisItem(
          description: 'Yuqori - dam olish va meditatsiya qiling.',
          iconPath: Assets.icons.favourite.svg(),
          percentage: model.stress!,
          status: 'Normal',
        ),
      if (model.sleep != null)
        AnalysisItem(
          description: 'Yetarli emas - Kechqurun ertaroq uxlashni odat qiling!',
          iconPath: Assets.icons.moon.svg(),
          percentage: model.sleep!,
          status: 'Normal',
        ),
    ];
  }

  Future<void> shareResults(ScreenshotController controller) async {
    emit(state.copyWith(isSharing: true));
    try {
      final imageBytes = await controller.capture(
        delay: const Duration(milliseconds: 350),
        pixelRatio: 2.0,
      );
      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot.');
      }

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/calora_analysis.png').create();
      await file.writeAsBytes(imageBytes);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
      log('Share result: ${result.status} ${result.raw}');
    } catch (e, s) {
      log('Share error: $e', stackTrace: s);
      publish(
        CaloraAiCalculateEffect.error(
          'Could not share results: ${e.toString()}',
        ),
      );
    } finally {
      emit(state.copyWith(isSharing: false));
    }
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }
}
