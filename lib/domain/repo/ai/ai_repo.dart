import 'package:calora/domain/model/base_response/base_response.dart';
import 'package:calora/domain/model/face_analysis/face_analysis_model.dart';

abstract class AiRepo {
  Future<BaseResponse<FaceAnalysisModel>> analyzeFace(String filePath);
}
