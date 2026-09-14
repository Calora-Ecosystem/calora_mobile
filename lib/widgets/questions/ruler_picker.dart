import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A horizontal, swipe-to-set ruler for whole-number values (height in cm,
/// weight in kg …). No keyboard: the user just drags the ruler under a fixed
/// centre pointer, the big value updates live, and it snaps to the nearest
/// tick on release. Emits its initial value once on mount so the "Next" button
/// enables immediately — the user can accept the sensible default or nudge it.
class RulerPicker extends StatefulWidget {
  final int min;
  final int max;
  final int initial;
  final String unit;
  final ValueChanged<int> onChanged;

  const RulerPicker({
    super.key,
    required this.min,
    required this.max,
    required this.initial,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  /// Pixels between two consecutive unit ticks.
  static const double _tick = 12.0;
  static const double _rulerHeight = 96.0;

  late final ScrollController _controller;
  late int _value;
  int? _lastHaptic;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(widget.min, widget.max);
    _controller = ScrollController(
      initialScrollOffset: (_value - widget.min) * _tick,
    );
    _lastHaptic = _value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _valueFromOffset(double offset) =>
      (widget.min + (offset / _tick).round()).clamp(widget.min, widget.max);

  bool _onNotification(ScrollNotification n) {
    final v = _valueFromOffset(_controller.offset);
    if (v != _value) {
      setState(() => _value = v);
      if (v != _lastHaptic) {
        _lastHaptic = v;
        HapticFeedback.selectionClick();
      }
    }
    if (n is ScrollEndNotification) _snap(v);
    return false;
  }

  void _snap(int v) {
    final target = (v - widget.min) * _tick;
    if ((_controller.offset - target).abs() > 0.5) {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    }
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            '$_value'.text(44, 50, 800).c(colors.accentSub),
            const SizedBox(width: 6),
            widget.unit.text(16, 20, 600).c(colors.textSub),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _rulerHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final centerPad = width / 2;
              final totalWidth = (widget.max - widget.min) * _tick + width;
              return Stack(
                alignment: Alignment.center,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: _onNotification,
                    child: SingleChildScrollView(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: totalWidth,
                        height: _rulerHeight,
                        child: CustomPaint(
                          painter: _RulerPainter(
                            min: widget.min,
                            max: widget.max,
                            tick: _tick,
                            centerPad: centerPad,
                            tickColor: colors.strokeSub,
                            majorColor: colors.neutral600Secondary,
                            labelColor: colors.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Fixed centre pointer the ruler slides under.
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 28, color: colors.accentSub),
                        Container(
                          width: 3,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.accentSub,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final int min;
  final int max;
  final double tick;
  final double centerPad;
  final Color tickColor;
  final Color majorColor;
  final Color labelColor;

  _RulerPainter({
    required this.min,
    required this.max,
    required this.tick,
    required this.centerPad,
    required this.tickColor,
    required this.majorColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final majorPaint = Paint()
      ..color = majorColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const top = 8.0;
    for (int v = min; v <= max; v++) {
      final x = centerPad + (v - min) * tick;
      final isMajor = v % 10 == 0;
      final isMedium = v % 5 == 0;
      final height = isMajor ? 44.0 : (isMedium ? 30.0 : 20.0);
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        isMajor ? majorPaint : minorPaint,
      );
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$v',
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, top + height + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.min != min ||
      old.max != max ||
      old.tick != tick ||
      old.centerPad != centerPad ||
      old.tickColor != tickColor ||
      old.majorColor != majorColor ||
      old.labelColor != labelColor;
}
