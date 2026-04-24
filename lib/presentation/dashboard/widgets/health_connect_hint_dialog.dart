// lib/presentation/dashboard/widgets/health_connect_hint_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';

/// Pre-permission rationale dialog shown before we call the system
/// Health Connect (Android) / HealthKit (iOS) permission prompt.
///
/// The user is told why we want access to the Health repository — they can
/// accept (triggering the OS prompt, and falling back to device settings if
/// the prompt is suppressed) or decline (falling back to the pedometer
/// sensor).
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
        return 'sog\'liq app\'ingiz';
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
            'Qadamlaringizni aniq hisoblashga ruxsat bering',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_repoName orqali $_sourceAppName\'dagi qadam ma\'lumotlaringizni '
            'o\'qishimizga ruxsat bersangiz:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const _BenefitRow(text: 'Aniqroq qadam hisobi'),
          const _BenefitRow(text: 'Soat va fitnes trekkeringiz qo\'shiladi'),
          const _BenefitRow(text: 'Kun davomidagi barcha harakat'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ruxsat bermasangiz, telefon sensorida qadamlar sanalib '
                    'turadi — lekin aniqligi pastroq bo\'lishi mumkin.',
                    style: TextStyle(fontSize: 12, height: 1.4),
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
                  child: const Text('Yo\'q'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAccept();
                  },
                  child: const Text('Ha'),
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
