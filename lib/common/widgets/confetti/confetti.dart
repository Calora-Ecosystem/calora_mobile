import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class PremiumConfettiOverlay extends StatefulWidget {
  const PremiumConfettiOverlay({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'premium_confetti',
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => const PremiumConfettiOverlay(),
      transitionBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  State<PremiumConfettiOverlay> createState() => _PremiumConfettiOverlayState();
}

class _PremiumConfettiOverlayState extends State<PremiumConfettiOverlay> with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(milliseconds: 650));
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scale = Tween<double>(begin: 0.7, end: 1.35).animate(
      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _confetti.play();
      _anim.forward();

      // 900ms dan keyin o‘zi yopilsin
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            minBlastForce: 30,
            maxBlastForce: 100,
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 100,
            gravity: 0.1,
            emissionFrequency: 0.1,
            minimumSize: const Size(6, 6),
            maximumSize: const Size(10, 10),
            colors: const [Colors.orange, Colors.yellow, Colors.green, Colors.red, Colors.deepPurple],
          ),
        ],
      ),
    );
  }
}
