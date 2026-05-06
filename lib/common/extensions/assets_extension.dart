import 'package:calora/common/constants/app_configs.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:flutter/foundation.dart';

/// Resolves the asset/file base URL from the active environment so prod
/// builds don't accidentally fetch images from staging.
/// Mirrors the routing in [network_module.dart] and
/// [custom_cached_network_image.dart].
String get baseUrl {
  final apiBase = kReleaseMode ? AppConfigs.baseUrl : AppConfigs.stagingBaseUrl;
  if (apiBase.isEmpty) return '';
  final normalized = apiBase.endsWith('/') ? apiBase : '$apiBase/';
  return '${normalized}file/';
}

const String abstractImageUrl = 'images/abstract.png';

extension CourseRequestX on CourseRequest {
  String? _getAssetUrl(String type) {
    final asset = assets?.firstWhere(
      (a) => a['type'] == type,
      orElse: () => {},
    );

    final url = asset?['url'];
    if (url == null || url.isEmpty) return null;

    return url.startsWith('http') ? url : url;
  }

  String? get mainImage => _getAssetUrl('MainImage');

  String? get subCoverImage => _getAssetUrl('SubCoverImage');
}

extension MealTypeDataX on MealTypeData {
  String get fullImageUrl =>
      imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl';
}

extension FoodModelX on FoodModel {
  String get fullImageUrl =>
      coverUrl.startsWith('http') ? coverUrl : '$baseUrl$coverUrl';
}

extension ImageUrlExtension on String {
  String get imageUrl => startsWith('http') ? this : '$baseUrl$this';
}

extension LessonAssetsExtension on LessonRequest {
  String? _getAssetUrl(String type) {
    final asset = assets.firstWhere(
      (a) => a.type == type,
      orElse: () => const LessonAsset(type: '', url: ''),
    );

    if (asset.url.isEmpty) return null;

    return asset.url.startsWith('http') ? asset.url : '$baseUrl${asset.url}';
  }

  String? get videoUrl => _getAssetUrl('Video');

  String? get coverImageUrl => _getAssetUrl('CoverImage');
}

extension ExerciseAssetX on ExerciseAsset {
  String get onlyUrl => url;
}
