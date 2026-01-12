import 'dart:math';

import 'package:easy_localization/easy_localization.dart';

extension DoubleExtension on double {
  String toPrettyFormat({
    String? currency,
    int decimalPlaces = 3,
    bool roundUp = true,
  }) {
    double valueToFormat;

    if (roundUp) {
      valueToFormat = (this * pow(10, decimalPlaces)).round() / pow(10, decimalPlaces);
    } else {
      valueToFormat = (this * pow(10, decimalPlaces)).truncate() / pow(10, decimalPlaces);
    }

    final pattern = decimalPlaces > 0 ? '#,##0.${'#' * decimalPlaces}' : '#,##0';

    final numberFormat = NumberFormat(pattern, 'en_US');
    final formatted = numberFormat.format(valueToFormat).replaceAll(',', ' ');

    return currency != null ? '$formatted $currency' : formatted;
  }
}

extension NumExtension on num {
  String toPrettyFormat({
    String? currency,
    int decimalPlaces = 3,
    bool roundUp = true,
  }) {
    num valueToFormat;

    if (roundUp) {
      valueToFormat = (this * pow(10, decimalPlaces)).round() / pow(10, decimalPlaces);
    } else {
      valueToFormat = (this * pow(10, decimalPlaces)).truncate() / pow(10, decimalPlaces);
    }

    final pattern = decimalPlaces > 0 ? '#,##0.${'#' * decimalPlaces}' : '#,##0';

    final numberFormat = NumberFormat(pattern, 'en_US');
    final formatted = numberFormat.format(valueToFormat).replaceAll(',', ' ');

    return currency != null ? '$formatted $currency' : formatted;
  }

  String formatPrice({String separator = ' ', int maxDecimalDigits = 0}) {
    final isNegative = this < 0;
    final value = this.abs();

    final hasDecimals = value % 1 != 0;
    final numberString = hasDecimals ? value.toStringAsFixed(maxDecimalDigits) : value.toInt().toString();

    final parts = numberString.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      final posFromEnd = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(separator);
    }

    final formattedInt = buffer.toString();
    final formattedDecimal = (decimalPart != null && decimalPart.replaceAll('0', '').isNotEmpty) ? '.$decimalPart' : '';

    return '${isNegative ? '-' : ''}$formattedInt$formattedDecimal';
  }
}
