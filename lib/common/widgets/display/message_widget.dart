import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/display/display_message.dart';
import 'package:calora/common/widgets/display/display_type.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({super.key, required this.message, required this.onClosed});

  final DisplayMessage message;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          message.onTap?.call();
          onClosed();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 72),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: const Offset(0, 16),
                  child: Container(
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: message.type.shadow(context), blurRadius: 50)],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: message.type.fill(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: message.type.stroke(context)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: (message.title ?? message.description).text(16, 16, 500),
                    subtitle: message.title == null ? null : message.description.text(14, 14, 500),
                    leading: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: Center(child: message.type.icon(context)),
                    ),
                    trailing: IconButton(onPressed: onClosed, icon: Icon(Icons.close)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
