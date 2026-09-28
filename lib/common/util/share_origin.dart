import 'package:flutter/widgets.dart';

/// Anchor rect for the native share sheet (`ShareParams.sharePositionOrigin`).
///
/// iOS presents the share sheet as a popover on iPad, and on iOS 26 on
/// iPhone too; share_plus then rejects an empty or off-screen origin and the
/// sheet never opens. Pass the tapped widget's [context] to anchor the
/// popover to it; if that widget isn't laid out, a small rect in the middle
/// of the screen is used so the share still works.
Rect shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize && !box.size.isEmpty) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: size.center(Offset.zero),
    width: 1,
    height: 1,
  );
}
