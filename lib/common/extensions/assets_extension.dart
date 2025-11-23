import 'package:calora/domain/model/lesson/lesson_request.dart';

import '../../domain/model/course/course_request.dart';

const baseUrl = "https://staging.calora.uz/api/file/";

extension CourseRequestX on CourseRequest {
  String? get mainImage {
    final url = assets?.firstWhere((a) => a['type'] == 'MainImage', orElse: () => {})['url'];
    return url != null ? "$baseUrl$url" : null;
  }

  String? get subCoverImage {
    final url = assets?.firstWhere((a) => a['type'] == 'SubCoverImage', orElse: () => {})['url'];
    return url != null ? "$baseUrl$url" : null;
  }
}

extension LessonAssetsExtension on LessonRequest {
  String? get videoUrl {
    try {
      final videoAsset = assets.firstWhere(
        (a) => a.type == 'Video',
        orElse: () => LessonAsset(type: 'Video', url: ''),
      );
      return videoAsset.url.isNotEmpty ? 'https://staging.calora.uz/api/file/${videoAsset.url}' : null;
    } catch (_) {
      return null;
    }
  }

  String? get coverImageUrl {
    try {
      final coverAsset = assets.firstWhere(
        (a) => a.type == 'CoverImage',
        orElse: () => LessonAsset(type: 'CoverImage', url: ''),
      );
      return coverAsset.url.isNotEmpty ? 'https://staging.calora.uz/api/file/${coverAsset.url}' : null;
    } catch (_) {
      return null;
    }
  }
}
