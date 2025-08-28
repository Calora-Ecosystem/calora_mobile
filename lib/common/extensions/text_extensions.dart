import 'package:flutter/material.dart';

extension TextStringExtensions on String? {
  Text text(
      double size,
      double height,
      int weight,
      ) =>
      Text(
        this ?? '',
        style: TextStyle(
          fontSize: size,
          height: height / size,
          fontWeight: FontWeight.values[weight ~/ 100 - 1],
        ),
      );
}

extension TextStyleExtensions on TextStyle {
  TextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) =>
      TextStyle(
        inherit: inherit ?? this.inherit,
        color: this.foreground == null && foreground == null ? color ?? this.color : null,
        backgroundColor: this.background == null && background == null
            ? backgroundColor ?? this.backgroundColor
            : null,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        fontStyle: fontStyle ?? this.fontStyle,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        wordSpacing: wordSpacing ?? this.wordSpacing,
        textBaseline: textBaseline ?? this.textBaseline,
        height: height ?? this.height,
        locale: locale ?? this.locale,
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
        decoration: decoration ?? this.decoration,
        decorationColor: decorationColor ?? this.decorationColor,
        decorationStyle: decorationStyle ?? this.decorationStyle,
        decorationThickness: decorationThickness ?? this.decorationThickness,
        overflow: overflow ?? this.overflow,
      );
}

extension TextExtensions on Text {
  Text copyWith({
    Key? key,
    String? data,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) =>
      Text(
        data ?? this.data!,
        key: key ?? this.key,
        style: style ?? this.style,
        strutStyle: strutStyle ?? this.strutStyle,
        textAlign: textAlign ?? this.textAlign,
        textDirection: textDirection ?? this.textDirection,
        locale: locale ?? this.locale,
        softWrap: softWrap ?? this.softWrap,
        overflow: overflow ?? this.overflow,
        maxLines: maxLines ?? this.maxLines,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        textWidthBasis: textWidthBasis ?? this.textWidthBasis,
        textHeightBehavior: textHeightBehavior ?? this.textHeightBehavior,
        selectionColor: selectionColor ?? this.selectionColor,
      );

  Text c(Color color) => copyWith(
        style: (style ?? const TextStyle()).copyWith(color: color),
      );
}
