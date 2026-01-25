import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/switch/custom_switch.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ExpandableContainer extends StatefulWidget {
  final String title;
  final String? info;
  final List<Widget>? children;
  final EdgeInsets margin;
  final EdgeInsets tilePadding;
  final double minTileHeight;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final bool useSwitch;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const ExpandableContainer({
    super.key,
    required this.title,
    this.info,
    this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    this.minTileHeight = 48,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.useSwitch = false,
    this.tilePadding = const EdgeInsets.symmetric(horizontal: 20),
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  }) : assert(
         info != null || children != null,
         'Either value or children must be provided',
       );

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer> {
  bool _isExpanded = false;
  final ExpansibleController _controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleExpansionChanged(bool expanded) {
    setState(() => _isExpanded = expanded);
    widget.onExpansionChanged?.call(expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      margin: widget.margin,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData(
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        child: RepaintBoundary(
          child: ExpansionTile(
            controller: _controller,
            onExpansionChanged: _handleExpansionChanged,
            tilePadding: widget.tilePadding,
            enabled: !widget.useSwitch,
            initiallyExpanded: widget.initiallyExpanded,
            childrenPadding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12,
            ),
            visualDensity: VisualDensity.standard,
            backgroundColor: widget.backgroundColor ?? context.colors.white,
            minTileHeight: widget.minTileHeight,
            collapsedBackgroundColor:
                widget.collapsedBackgroundColor ?? context.colors.white,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            trailing: widget.useSwitch
                ? CustomSwitch(
                    initialValue: _isExpanded,
                    onChanged: (value) {
                      setState(() => _isExpanded = value);
                      if (value) {
                        _controller.expand();
                      } else {
                        _controller.collapse();
                      }
                      widget.onExpansionChanged?.call(value);
                    },
                  )
                : AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    curve: Curves.easeInOut,
                    child: Assets.icons.arrowDown.svg(
                      height: 20,
                      width: 20,
                      colorFilter: ColorFilter.mode(
                        context.colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
            title: AbsorbPointer(
              absorbing: widget.useSwitch,
              child: widget.title
                  .text(16, 20, 400)
                  .c(context.colors.textPrimary),
            ),
            children:
                widget.children ??
                [
                  (widget.info ?? '')
                      .text(14, 16, 400)
                      .c(context.colors.textSub),
                ],
          ),
        ),
      ),
    );
  }
}
