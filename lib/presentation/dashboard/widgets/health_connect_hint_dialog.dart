// lib/presentation/dashboard/widgets/health_connect_hint_dialog.dart

import 'package:calora/common/service/installed_health_apps_service.dart';
import 'package:flutter/material.dart';

class HealthConnectHintDialog extends StatelessWidget {
  final String detectedApp;
  final VoidCallback onOpenPressed;
  final VoidCallback onDismiss;

  const HealthConnectHintDialog({
    super.key,
    required this.detectedApp,
    required this.onOpenPressed,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String detectedApp,
    required VoidCallback onOpenPressed,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HealthConnectHintDialog(
        detectedApp: detectedApp,
        onOpenPressed: onOpenPressed,
        onDismiss: onDismiss,
      ),
    );
  }

  String get _appName {
    switch (detectedApp) {
      case 'samsung_health':
        return 'Samsung Health';
      case 'mi_fitness':
        return 'Mi Fitness';
      default:
        return 'sog\'liq';
    }
  }

  String get _instructions {
    switch (detectedApp) {
      case 'samsung_health':
        return 'Samsung Health → Sozlamalar → Health Connect → Ulash → "Qadamlar"ni yoqing';
      case 'mi_fitness':
        return 'Mi Fitness → Profil → Sozlamalar → Health Connect → "Qadamlar"ni yoqing';
      default:
        return 'Sog\'liq app\'ingiz sozlamalarida Health Connect bo\'limini toping va "Qadamlar"ni yoqing';
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
            'Qadamlaringizni aniqroq hisoblaymizmi?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Telefoningizda $_appName app\'i bor, lekin u bizning app\'imizga '
            'ulanmagan. Ulansangiz:',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _instructions,
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
                    onDismiss();
                  },
                  child: const Text('Keyinroq'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onOpenPressed();
                  },
                  child: const Text('Ochish'),
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
