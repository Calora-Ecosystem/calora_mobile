import 'dart:math' as Math show pow;

extension DoubleFormatting on double {
  String asFixedRounded(int decimals) => toStringAsFixed(decimals);

  String asFixedTruncated(int decimals) {
    double factor = Math.pow(10, decimals).toDouble();
    double truncated = (this * factor).truncateToDouble() / factor;
    return truncated.toStringAsFixed(decimals);
  }
}
