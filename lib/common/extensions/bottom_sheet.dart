import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

extension ModalSheetExtension on BuildContext {
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    Color? backgroundColor,
    ScrollController? scrollController,
    double maxHeightFactor = 0.90,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenH = MediaQuery.of(context).size.height;
        final maxH = screenH * maxHeightFactor;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxH,
                  minWidth: double.infinity,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor ?? context.colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        height: 3,
                        width: 40,
                        color: context.colors.neutral200Stroke,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
