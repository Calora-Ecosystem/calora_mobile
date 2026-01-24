import 'dart:ui';

import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/display/display_message.dart';
import 'package:calora/common/widgets/display/display_type.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  final DisplayMessage message;
  final VoidCallback onClosed;
  const MessageWidget({super.key, required this.message, required this.onClosed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: GestureDetector(
          onTap: () {
            message.onTap?.call();
            onClosed();
          },
          child: Material(
            color: context.colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(0xFF141417).withOpacityLevel(0.6),
                  ),

                  child: Row(
                    children: [
                      Padding(padding: const EdgeInsets.all(12), child: message.type.icon(context)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          child: Column(
                            crossAxisAlignment: .start,
                            mainAxisSize: .min,
                            children: [
                              if (message.title != null) ...[
                                (message.title ?? '').text(24, 24, 700).c(context.colors.white),
                                const SizedBox(height: 4),
                              ],
                              message.description
                                  .text(14, 16, 400)
                                  .c(context.colors.white)
                                  .copyWith(maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Assets.icons.cancel.svg(
                          colorFilter: ColorFilter.mode(context.colors.zirkon, BlendMode.srcIn),
                          height: 14,
                          width: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
