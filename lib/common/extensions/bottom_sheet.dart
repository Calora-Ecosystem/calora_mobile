import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

extension ModalSheetExtension on BuildContext {
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    double initialChildSize = 0.85,
    double minChildSize = 0.6,
    double maxChildSize = 0.95,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useRootNavigator: false,
      builder: (context) {
        return AnimatedPadding(
          padding: MediaQuery.of(context).viewInsets,
          duration: const Duration(milliseconds: 100),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: backgroundColor ?? context.colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(height: 3, width: 40, color: context.colors.neutral200Stroke),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(controller: scrollController, padding: EdgeInsets.zero, children: [child]),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
