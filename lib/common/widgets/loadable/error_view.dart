import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.retry, this.error});

  final VoidCallback retry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Text('TODO: ERROR VIEW');
  }
}
