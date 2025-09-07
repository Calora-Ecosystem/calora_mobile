import 'package:calora/common/extensions/text_extensions.dart';
import 'package:flutter/material.dart';

class TabBarItemWidget extends StatelessWidget {
  final String name;

  TabBarItemWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [name.text(14, 18, 500)],
      ),
    );
  }
}
