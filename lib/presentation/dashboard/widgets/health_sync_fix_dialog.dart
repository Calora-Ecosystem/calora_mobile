// lib/presentation/dashboard/widgets/health_sync_fix_dialog.dart

import 'package:flutter/material.dart';

/// Shown when Health permission is granted but Health Connect is
/// reporting ~0 steps because the user's primary tracker (Samsung
/// Health, Mi Fitness, …) hasn't been configured to sync into it.
///
/// Offers three actions: open the source app so the user can flip the
/// sync toggle, fall back to the device pedometer, or dismiss for now.
class HealthSyncFixDialog extends StatelessWidget {
  final String detectedApp;
  final VoidCallback onOpenSourceApp;
  final VoidCallback onUseSensorInstead;
  final VoidCallback onDismiss;

  const HealthSyncFixDialog({
    super.key,
    required this.detectedApp,
    required this.onOpenSourceApp,
    required this.onUseSensorInstead,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String detectedApp,
    required VoidCallback onOpenSourceApp,
    required VoidCallback onUseSensorInstead,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HealthSyncFixDialog(
        detectedApp: detectedApp,
        onOpenSourceApp: onOpenSourceApp,
        onUseSensorInstead: onUseSensorInstead,
        onDismiss: onDismiss,
      ),
    );
  }

  String get _sourceAppName {
    switch (detectedApp) {
      case 'samsung_health':
        return 'Samsung Health';
      case 'mi_fitness':
        return 'Mi Fitness';
      default:
        return 'fitnes app\'ingiz';
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
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sync_problem,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Qadamlar sinxronlanmayapti',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_sourceAppName\'da qadam ma\'lumotlari bor, lekin Health '
            'Connect\'ga sinxronlanmayapti. Iltimos, $_sourceAppName\'ni '
            'oching va Sozlamalar → Health Connect bilan ulanish bo\'limidan '
            'sinxronlashni yoqing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onOpenSourceApp();
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('$_sourceAppName\'ni ochish'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onUseSensorInstead();
              },
              child: const Text('Telefon sensoridan foydalanish'),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss();
            },
            child: const Text('Keyinroq'),
          ),
        ],
      ),
    );
  }
}
