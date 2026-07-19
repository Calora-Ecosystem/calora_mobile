import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.retry, this.error});

  final VoidCallback retry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error ?? Strings.errorViewMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Button(text: Strings.tryAgain, width: 200, onPressed: retry),
          ],
        ),
      ),
    );
  }
}
