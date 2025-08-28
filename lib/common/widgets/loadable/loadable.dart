import 'package:calora/common/widgets/loadable/error_view.dart';
import 'package:calora/common/widgets/loadable/loading_view.dart';
import 'package:flutter/material.dart';

class Loadable extends StatelessWidget {
  const Loadable({
    super.key,
    this.loading = false,
    this.error = false,
    this.retry,
    required this.builder,
  });

  final bool loading;
  final bool error;
  final VoidCallback? retry;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (error) return ErrorView(retry: retry ?? () {});
    return builder(context);
  }
}
