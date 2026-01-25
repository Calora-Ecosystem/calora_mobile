import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:calora/common/constants/app_configs.dart';
import 'package:calora/common/extensions/color_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomCachedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;
  final Widget? errorWidgetIcon;
  final double placeHolderSizeRatio;
  final BoxFit fit;
  final double radius;
  final Color? imageColor;
  final Color? widgetBgColor;
  final BlendMode? colorBlendMode;
  final String? cacheKey;
  final bool showLoadingIndicator;
  final BoxShape shape;
  final BorderRadius? customBorderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final String? semanticLabel;

  factory CustomCachedNetworkImage.avatar({
    required String? imageUrl,
    double size = 48,
    double radius = 100,
    Color? backgroundColor,
    Widget? errorIcon,
    String? cacheKey,
  }) {
    final isValidUrl = imageUrl != null && imageUrl.trim().isNotEmpty;

    developer.log(
      '🎯 Avatar Factory Called:',
      name: 'CustomCachedNetworkImage',
    );
    developer.log('  size: $size', name: 'CustomCachedNetworkImage');
    developer.log('  imageUrl: $imageUrl', name: 'CustomCachedNetworkImage');
    developer.log(
      '  isValidUrl: $isValidUrl',
      name: 'CustomCachedNetworkImage',
    );

    return CustomCachedNetworkImage(
      imageUrl: isValidUrl ? imageUrl : null,
      height: size,
      width: size,
      radius: radius,
      widgetBgColor: backgroundColor,
      errorWidgetIcon: errorIcon,
      cacheKey: cacheKey,
      semanticLabel: 'User avatar',
      showLoadingIndicator: isValidUrl,
    );
  }

  factory CustomCachedNetworkImage.thumbnail({
    required String? imageUrl,
    double height = 120,
    double width = 120,
    double radius = 8,
    BoxFit fit = BoxFit.cover,
    String? cacheKey,
  }) {
    return CustomCachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      radius: radius,
      shape: BoxShape.rectangle,
      fit: fit,
      cacheKey: cacheKey,
      semanticLabel: 'Thumbnail image',
    );
  }

  factory CustomCachedNetworkImage.banner({
    required String? imageUrl,
    double? width,
    double height = 200,
    double radius = 0,
    BoxFit fit = BoxFit.cover,
    String? cacheKey,
  }) {
    return CustomCachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      radius: radius,
      shape: BoxShape.rectangle,
      fit: fit,
      cacheKey: cacheKey,
      semanticLabel: 'Banner image',
    );
  }

  const CustomCachedNetworkImage({
    super.key,
    required this.imageUrl,
    required this.height,
    this.width,
    this.errorWidgetIcon,
    this.placeHolderSizeRatio = 1,
    this.fit = BoxFit.cover,
    this.radius = 100,
    this.imageColor,
    this.widgetBgColor,
    this.colorBlendMode,
    this.cacheKey,
    this.showLoadingIndicator = true,
    this.shape = BoxShape.circle,
    this.customBorderRadius,
    this.border,
    this.shadows,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = _sanitizeUrl(imageUrl);

    if (sanitizedUrl == null) return _buildError(context);

    final borderRadius =
        customBorderRadius ??
        (shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null);

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final memHeight = width != null ? (height * pixelRatio).toInt() : null;
    final memWidth = width != null ? (width! * pixelRatio).toInt() : null;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        border: border,
        boxShadow: shadows,
      ),
      clipBehavior: Clip.hardEdge,
      child: CachedNetworkImage(
        cacheKey: cacheKey ?? sanitizedUrl,
        imageUrl: sanitizedUrl,
        fit: fit,
        color: imageColor,
        colorBlendMode: colorBlendMode,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        progressIndicatorBuilder: showLoadingIndicator
            ? (context, url, progress) => _buildPlaceholder(context, progress)
            : null,
        errorWidget: (context, url, error) => _buildError(context),
      ),
    );
  }

  String? _sanitizeUrl(String? url) {
    if (url == null) return null;

    String trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final String baseUrl = kReleaseMode
        ? AppConfigs.baseUrl
        : AppConfigs.stagingBaseUrl;
    trimmed = '${baseUrl}file/$trimmed';

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority) return null;
    return trimmed;
  }

  Widget _buildPlaceholder(BuildContext context, DownloadProgress? progress) {
    final bgColor = widgetBgColor ?? Theme.of(context).cardColor;
    final indicatorSize = (height / 3).clamp(16.0, 32.0);

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: progress?.progress != null
          ? SizedBox(
              height: indicatorSize,
              width: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress?.progress,
              ),
            )
          : SizedBox(
              height: indicatorSize,
              width: indicatorSize,
              child: const CupertinoActivityIndicator(),
            ),
    );
  }

  Widget _buildError(BuildContext context) {
    final bgColor =
        widgetBgColor ?? Theme.of(context).disabledColor.withOpacityLevel(0.1);

    return Container(
      height: height,
      width: width,
      color: bgColor,
      alignment: Alignment.center,
      child:
          errorWidgetIcon ??
          Icon(
            Icons.image_not_supported_outlined,
            size: (height / 2).clamp(16, 48),
            color: Theme.of(context).disabledColor,
          ),
    );
  }
}
