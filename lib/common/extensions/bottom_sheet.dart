import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

extension ModalSheetExtension on BuildContext {
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    Color? backgroundColor,
    ScrollController? scrollController,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? context.colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      height: 3,
                      width: 40,
                      color: context.colors.neutral200Stroke,
                    ),
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
