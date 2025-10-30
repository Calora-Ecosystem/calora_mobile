import 'package:calora/presentation/ai/management/calora_ai_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class CaloraAiManager extends Manager<CaloraAiState, CaloraAiEffect> {
  CaloraAiManager() : super(const CaloraAiState());

  void openConfirmPage() {
    publish(const CaloraAiEffect.showConfirmDialog());
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      publish(const CaloraAiEffect.navigateToCamera());
    }
  }
}
