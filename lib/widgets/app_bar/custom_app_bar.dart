import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Object title;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;
  final bool showBackButton;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.trailing,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;

    if (title is String) {
      titleWidget = (title as String).text(17, 22, 600).c(context.colors.black);
    } else if (title is Widget) {
      titleWidget = title as Widget;
    } else {
      titleWidget = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.strokeSoft)),
      ),
      child: AppBar(
        backgroundColor: backgroundColor ?? context.colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading:
            leading ??
            (showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                  )
                : null),
        title: titleWidget,
        actions: trailing != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: trailing!,
                ),
              ]
            : null,
      ),
    );
  }
}
