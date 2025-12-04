import 'package:flutter/material.dart';

extension MetricsController on TextEditingController {
  void handleMetricsChange({required String metrics, required bool isUserEditing}) {
    if (metrics.isEmpty || !isUserEditing) return;

    final currentValue = text;
    final selection = this.selection;

    if (selection.base.offset < currentValue.length - metrics.length) {
      return;
    }

    String numericValue = currentValue.replaceAll(RegExp(r'[^0-9.]'), '');

    if (numericValue.split('.').length > 2) {
      final parts = numericValue.split('.');
      numericValue = '${parts[0]}.${parts.sublist(1).join()}';
    }

    // Yangi qiymat
    final newValue = '$numericValue $metrics';

    if (currentValue != newValue) {
      value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: numericValue.length),
      );
    }
  }
}
