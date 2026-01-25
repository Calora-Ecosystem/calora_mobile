import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DefaultRefreshIndicator extends StatefulWidget {
  const DefaultRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset,
    this.notificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final double? edgeOffset;
  final Widget child;
  final bool Function(ScrollNotification)? notificationPredicate;

  @override
  State<DefaultRefreshIndicator> createState() =>
      _DefaultRefreshIndicatorState();
}

class _DefaultRefreshIndicatorState extends State<DefaultRefreshIndicator> {
  @override
  Widget build(BuildContext context) {
    return CustomMaterialIndicator.adaptive(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        return widget.onRefresh();
      },
      notificationPredicate:
          widget.notificationPredicate ??
          CustomRefreshIndicator.defaultScrollNotificationPredicate,
      displacement: 0,
      edgeOffset: widget.edgeOffset ?? 0,
      backgroundColor: Colors.transparent,
      leadingScrollIndicatorVisible: true,
      trailingScrollIndicatorVisible: false,
      indicatorBuilder: (context, controller) {
        final isAtTop = controller.edge == IndicatorEdge.leading;
        return AnimatedOpacity(
          opacity: isAtTop ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(Assets.icons.icLogo.path),
                  ),
                ),
              ),
              CircularProgressIndicator(
                color: context.colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
