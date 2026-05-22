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

/// Asset-parsing helpers for [ExercisesRequest] / [ExerciseAsset].
///
/// Keeps URL resolution + asset-type lookup out of UI widgets so the
/// rendering code stays a thin presentational layer and the parsing
/// can be unit-tested in isolation.
extension ExerciseAssetX on ExerciseAsset {
  /// Returns the asset URL with the file-server base prepended when
  /// the backend returned a relative path (`videos/1.mp4` →
  /// `https://.../file/videos/1.mp4`). Absolute URLs (YouTube, etc.)
  /// pass through unchanged.
  String get fullUrl => url.startsWith('http') ? url : '$baseUrl$url';
}

extension ExercisesRequestX on ExercisesRequest {
  ExerciseAsset? _assetOfType(String type) {
    for (final asset in assets) {
      if (asset.type.toLowerCase() == type.toLowerCase()) return asset;
    }
    return null;
  }

  /// Preview asset (typically a short `.mp4` rendered as a looping
  /// muted GIF on the card). Resolved to an absolute URL.
  String? get previewAssetUrl {
    final raw = _assetOfType('Default')?.url.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '$baseUrl$raw';
  }

  /// YouTube tutorial URL — already absolute in the API payload.
  String? get youtubeAssetUrl {
    final raw = _assetOfType('Video')?.url.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}

extension ExerciseComputationX on ExerciseComputation {
  /// Localized formatter for the computation badge on the card
  /// ("5 daqiqa" for [ComputationType.duration], "25 marta" for
  /// [ComputationType.count]).
  ///
  /// `value` is **minutes** for Duration and **reps** for Count, per
  /// the backend contract. Pass the localized unit strings from the
  /// caller so this helper stays free of `easy_localization`
  /// dependency (and is testable).
  String format({required String durationUnit, required String countUnit}) {
    final n = value % 1 == 0 ? value.toInt().toString() : value.toString();
    switch (computationType) {
      case ComputationType.duration:
        return '$n $durationUnit';
      case ComputationType.count:
        return '$n $countUnit';
    }
  }
}
