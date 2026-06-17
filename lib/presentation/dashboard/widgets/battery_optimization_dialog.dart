// lib/presentation/dashboard/widgets/battery_optimization_dialog.dart

import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/device_care_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks the user to whitelist the app from battery optimization (and, on
/// aggressive OEMs, enable Autostart / background activity) so the step
/// foreground service isn't killed when the app is backgrounded.
///
/// Deep-links to the system / OEM screens via [DeviceCareService].
class BatteryOptimizationDialog extends StatelessWidget {
  const BatteryOptimizationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatteryOptimizationDialog(),
    );
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
            child: const Icon(
              Icons.battery_saver,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'battery_hint_title'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'battery_hint_body'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                DeviceCareService.requestIgnoreBatteryOptimizations();
              },
              icon: const Icon(Icons.battery_charging_full, size: 18),
              label: Text('battery_hint_allow'.tr()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                DeviceCareService.openAutoStartSettings();
              },
              icon: const Icon(Icons.settings_backup_restore, size: 18),
              label: Text('battery_hint_autostart'.tr()),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.later),
          ),
        ],
      ),
    );
  }
}
