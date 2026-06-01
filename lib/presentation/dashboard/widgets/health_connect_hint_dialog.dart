import 'dart:io';

import 'package:calora/common/gen/strings.dart';
import 'package:flutter/material.dart';

class HealthConnectHintDialog extends StatelessWidget {
  final String detectedApp;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const HealthConnectHintDialog({
    super.key,
    required this.detectedApp,
    required this.onAccept,
    required this.onDecline,
  });

  static Future<void> show({
    required BuildContext context,
    required String detectedApp,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HealthConnectHintDialog(
        detectedApp: detectedApp,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }

  String get _repoName {
    if (Platform.isIOS) return 'Apple Health';
    return 'Health Connect';
  }

  String get _sourceAppName {
    switch (detectedApp) {
      case 'samsung_health':
        return 'Samsung Health';
      case 'mi_fitness':
        return 'Mi Fitness';
      case 'ios':
        return 'Apple Health';
      default:
        return Strings.fallbackHealthApp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.green, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            Strings.healthHintTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Strings.healthHintSubtitle(
              sourceApp: _sourceAppName,
              repo: _repoName,
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _BenefitRow(text: Strings.healthHintBenefitAccuracy),
          _BenefitRow(text: Strings.healthHintBenefitDevices),
          _BenefitRow(text: Strings.healthHintBenefitAllday),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Strings.healthHintInfo,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDecline();
                  },
                  child: Text(Strings.dialogNo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAccept();
                  },
                  child: Text(Strings.dialogYes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
