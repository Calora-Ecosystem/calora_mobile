import 'package:flutter/material.dart';

/// A non-cancellable priming screen for the Android "Physical activity"
/// (ACTIVITY_RECOGNITION) permission that the on-device step sensor needs.
///
/// Design goals:
///  • Best-effort, friendly UX that explains *why* before the cold system
///    prompt — this is what maximises the grant rate.
///  • The user cannot dismiss it (no back button, no barrier tap, no close
///    icon): step counting is a core feature and can't start without the
///    permission, so we keep asking until it's granted.
///  • Gracefully handles a permanent denial ("Don't ask again") by guiding
///    the user to app settings and re-checking automatically on resume.
class ActivityPermissionDialog extends StatefulWidget {
  /// Triggers the system permission prompt; resolves to the granted state.
  final Future<bool> Function() onRequest;

  /// Re-reads the current permission state (used on resume / after the user
  /// returns from app settings).
  final Future<bool> Function() onCheckGranted;

  /// Whether the OS will no longer show the prompt (user chose "Don't ask
  /// again") — in which case we must route to app settings.
  final Future<bool> Function() onIsPermanentlyDenied;

  /// Opens this app's system settings page.
  final Future<void> Function() onOpenSettings;

  /// Called exactly once when the permission becomes granted, right before
  /// the dialog closes itself.
  final VoidCallback onGranted;

  const ActivityPermissionDialog({
    super.key,
    required this.onRequest,
    required this.onCheckGranted,
    required this.onIsPermanentlyDenied,
    required this.onOpenSettings,
    required this.onGranted,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<bool> Function() onRequest,
    required Future<bool> Function() onCheckGranted,
    required Future<bool> Function() onIsPermanentlyDenied,
    required Future<void> Function() onOpenSettings,
    required VoidCallback onGranted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ActivityPermissionDialog(
        onRequest: onRequest,
        onCheckGranted: onCheckGranted,
        onIsPermanentlyDenied: onIsPermanentlyDenied,
        onOpenSettings: onOpenSettings,
        onGranted: onGranted,
      ),
    );
  }

  @override
  State<ActivityPermissionDialog> createState() =>
      _ActivityPermissionDialogState();
}

class _ActivityPermissionDialogState extends State<ActivityPermissionDialog>
    with WidgetsBindingObserver {
  static const _accent = Color(0xFF22C55E);
  static const _accentDark = Color(0xFF16A34A);

  bool _busy = false;
  bool _needsSettings = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have granted the permission in app settings while we
    // were backgrounded — re-check and close ourselves if so.
    if (state == AppLifecycleState.resumed) {
      _recheck();
    }
  }

  Future<void> _recheck() async {
    if (_closed) return;
    final granted = await widget.onCheckGranted();
    if (granted) {
      _finishGranted();
    }
  }

  void _finishGranted() {
    if (_closed || !mounted) return;
    _closed = true;
    widget.onGranted();
    Navigator.of(context).pop();
  }

  Future<void> _onPrimaryTap() async {
    if (_busy) return;
    setState(() => _busy = true);

    if (_needsSettings) {
      await widget.onOpenSettings();
      if (mounted) setState(() => _busy = false);
      return;
    }

    final granted = await widget.onRequest();
    if (granted) {
      _finishGranted();
      return;
    }

    final permanent = await widget.onIsPermanentlyDenied();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _needsSettings = permanent;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Block every dismissal route — the user must grant to proceed.
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const SizedBox(height: 22),
              const Text(
                'Qadamlaringizni avtomatik sanaymiz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _needsSettings
                    ? 'Ruxsat o‘chirilgan. Iltimos, Sozlamalar → Ruxsatlar → '
                        'Jismoniy faollik (Physical activity) bo‘limidan ruxsat '
                        'bering — shundan keyin qadamlar avtomatik sanaladi.'
                    : 'Calora telefoningiz qadam sensoridan foydalanib, kunlik, '
                        'haftalik va oylik qadamlaringizni avtomatik hisoblaydi. '
                        'Buning uchun bir martalik “Jismoniy faollik” ruxsati kerak.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              _benefit(Icons.bolt_rounded, 'Real vaqtda — yurganingizda darhol'),
              _benefit(Icons.lock_outline_rounded,
                  'Maxfiy — hech qaysi boshqa ilovaga ulanmaysiz'),
              _benefit(Icons.battery_charging_full_rounded,
                  'Ilova yopiq bo‘lsa ham fonda sanaydi'),
              const SizedBox(height: 24),
              _primaryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accentDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4022C55E),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_walk_rounded,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE9FBEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_accent, _accentDark],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3322C55E),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy ? null : _onPrimaryTap,
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _needsSettings ? 'Sozlamalarni ochish' : 'Ruxsat berish',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
