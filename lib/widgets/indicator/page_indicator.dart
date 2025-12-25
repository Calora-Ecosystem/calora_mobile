import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final bool isActive = index == currentPage;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 48 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? context.colors.accentSoft : context.colors.accentWhite,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
