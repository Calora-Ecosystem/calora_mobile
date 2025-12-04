import 'dart:math';

import 'package:easy_localization/easy_localization.dart';

extension DoubleExtension on double {
  String toPrettyFormat({String? currency, int decimalPlaces = 3, bool roundUp = true}) {
    double valueToFormat;

    if (roundUp) {
      valueToFormat = (this * pow(10, decimalPlaces)).round() / pow(10, decimalPlaces);
    } else {
      valueToFormat = (this * pow(10, decimalPlaces)).truncate() / pow(10, decimalPlaces);
    }

    final pattern = decimalPlaces > 0 ? '#,##0.${'#' * decimalPlaces}' : '#,##0';

    final numberFormat = NumberFormat(pattern, 'en_US');
    final formatted = numberFormat.format(valueToFormat).replaceAll(',', ' ');

    return currency != null ? "$formatted $currency" : formatted;
  }
}

extension NumExtension on num {
  String toPrettyFormat({String? currency, int decimalPlaces = 3, bool roundUp = true}) {
    num valueToFormat;

    if (roundUp) {
      valueToFormat = (this * pow(10, decimalPlaces)).round() / pow(10, decimalPlaces);
    } else {
      valueToFormat = (this * pow(10, decimalPlaces)).truncate() / pow(10, decimalPlaces);
    }

    final pattern = decimalPlaces > 0 ? '#,##0.${'#' * decimalPlaces}' : '#,##0';

    final numberFormat = NumberFormat(pattern, 'en_US');
    final formatted = numberFormat.format(valueToFormat).replaceAll(',', ' ');

    return currency != null ? "$formatted $currency" : formatted;
  }
}
