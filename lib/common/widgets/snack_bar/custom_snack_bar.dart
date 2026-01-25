import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

enum SnackBarType { error, success, info }

class CustomSnackBar {
  static void show(BuildContext context, String message) {
    _show(context, message, SnackBarType.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, SnackBarType.success);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, SnackBarType.info);
  }

  static void _show(BuildContext context, String message, SnackBarType type) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackBarWidget(
        message: message,
        type: type,
        onDismiss: () {},
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1500), overlayEntry.remove);
  }
}

class _CustomSnackBarWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  final SnackBarType type;

  const _CustomSnackBarWidget({
    required this.message,
    required this.onDismiss,
    required this.type,
  });

  @override
  State<_CustomSnackBarWidget> createState() => _CustomSnackBarWidgetState();
}

class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor(BuildContext context) {
    switch (widget.type) {
      case SnackBarType.error:
        return context.colors.black;
      case SnackBarType.success:
        return context.colors.green;
      case SnackBarType.info:
        return context.colors.black;
    }
  }

  Widget _icon() {
    switch (widget.type) {
      case SnackBarType.error:
        return Assets.icons.errorIcon.svg();
      case SnackBarType.success:
        return Assets.icons.checkmarkCircle.svg();
      case SnackBarType.info:
        return Assets.icons.triangleInfo.svg();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _backgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacityLevel(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _icon(),
                const SizedBox(width: 8),
                Expanded(
                  child: widget.message.text(14, 18, 400).c(context.colors.textWhite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
