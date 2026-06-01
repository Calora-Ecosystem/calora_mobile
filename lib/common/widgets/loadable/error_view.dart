import 'package:calora/common/gen/strings.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.retry, this.error});

  final VoidCallback retry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        error ?? Strings.errorViewMessage,
        textAlign: TextAlign.center,
      ),
    );
  }
}
