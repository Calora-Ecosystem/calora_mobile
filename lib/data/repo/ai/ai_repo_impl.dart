import 'package:calora/data/api/ai_api.dart';
import 'package:calora/domain/model/base_response/base_response.dart';
import 'package:calora/domain/model/face_analysis/face_analysis_model.dart';
import 'package:calora/domain/repo/ai/ai_repo.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: AiRepo)
class AiRepoImpl implements AiRepo {
  final AiApi _api;

  AiRepoImpl(this._api);

  @override
  Future<BaseResponse<FaceAnalysisModel>> analyzeFace(String filePath) async {
    try {
      final response = await _api.analyzeFace(filePath);
      return BaseResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FaceAnalysisModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return BaseResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
          (json) => FaceAnalysisModel.fromJson(json as Map<String, dynamic>),
        );
      } else {
        rethrow;
      }
    }
  }
}
