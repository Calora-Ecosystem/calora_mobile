import 'package:calora/common/widgets/shimmer/shimmer_direction_enum.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  const Shimmer({
    super.key,
    this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.baseColor,
    this.highlightColor,
    this.direction = ShimmerDirection.topLeftToBottomRight,
  });

  final Widget? child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;
  final ShimmerDirection direction;

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: widget.duration);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  LinearGradient get gradient {
    final Color base = widget.baseColor ?? context.colors.white;

    final Color low = base.withValues(alpha: 0.4);
    final Color mid = (widget.highlightColor ?? base).withValues(alpha: 0.8);

    return LinearGradient(
      colors: [low, mid, low],
      stops: const [0.35, 0.50, 0.65],
      begin: const Alignment(-1.0, -1.0),
      end: const Alignment(1.0, 1.0),
      transform: _SlidingGradientTransform(
        slidePercent: _shimmerController.value,
        direction: widget.direction,
      ),
    );
  }

  bool get isSized => (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject() as RenderBox).size;

  Offset getDescendantOffset({required RenderBox descendant, Offset offset = Offset.zero}) {
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  Listenable get shimmerChanges => _shimmerController;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent, required this.direction});

  final double slidePercent;
  final ShimmerDirection direction;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    switch (direction) {
      case ShimmerDirection.leftToRight:
        return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
      case ShimmerDirection.rightToLeft:
        return Matrix4.translationValues(-bounds.width * slidePercent, 0.0, 0.0);
      case ShimmerDirection.topToBottom:
        return Matrix4.translationValues(0.0, bounds.height * slidePercent, 0.0);
      case ShimmerDirection.bottomToTop:
        return Matrix4.translationValues(0.0, -bounds.height * slidePercent, 0.0);
      case ShimmerDirection.topLeftToBottomRight:
        return Matrix4.translationValues(
          bounds.width * slidePercent,
          bounds.height * slidePercent,
          0.0,
        );
      case ShimmerDirection.bottomRightToTopLeft:
        return Matrix4.translationValues(
          -bounds.width * slidePercent,
          -bounds.height * slidePercent,
          0.0,
        );
    }
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.loading, required this.shimmerChild, this.child});

  final bool loading;
  final Widget shimmerChild;
  final Widget? child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachShimmerListener(retryIfNull: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachShimmerListener(retryIfNull: true);
  }

  void _attachShimmerListener({bool retryIfNull = false}) {
    final newChanges = Shimmer.of(context)?.shimmerChanges;
    if (!identical(newChanges, _shimmerChanges)) {
      _shimmerChanges?.removeListener(_onShimmerChange);
      _shimmerChanges = newChanges;
      _shimmerChanges?.addListener(_onShimmerChange);
    }

    if (retryIfNull && _shimmerChanges == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _attachShimmerListener(retryIfNull: false);
      });
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.loading) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loading) {
      return widget.child ?? widget.shimmerChild;
    }

    final shimmer = Shimmer.of(context);
    if (shimmer == null || !shimmer.isSized) {
      return widget.shimmerChild;
    }

    final shimmerSize = shimmer.size;
    final gradient = shimmer.gradient;
    final renderBox = context.findRenderObject();
    final offsetWithinShimmer = renderBox is RenderBox
        ? shimmer.getDescendantOffset(descendant: renderBox)
        : Offset.zero;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx,
            -offsetWithinShimmer.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.shimmerChild,
    );
  }
}
