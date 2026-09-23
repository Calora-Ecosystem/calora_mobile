import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for naming and creating a new group.
class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key, required this.onCreate});

  final void Function(String name) onCreate;

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'create_group'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'group_name'.tr().text(13, 16, 500).c(context.colors.textSub),
          const SizedBox(height: 8),
          CommonTextField(
            hint: 'group_name_hint'.tr(),
            controller: _controller,
          ),
          const SizedBox(height: 20),
          Button(
            text: 'create_group'.tr(),
            onPressed: () {
              final name = _controller.text.trim();
              if (name.isEmpty) return;
              widget.onCreate(name);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for joining a group by its invite code.
class JoinGroupSheet extends StatefulWidget {
  const JoinGroupSheet({super.key, required this.onJoin});

  final void Function(String code) onJoin;

  @override
  State<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<JoinGroupSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'join_by_code'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'invite_code'.tr().text(13, 16, 500).c(context.colors.textSub),
          const SizedBox(height: 8),
          CommonTextField(hint: 'enter_code'.tr(), controller: _controller),
          const SizedBox(height: 20),
          Button(
            text: 'join'.tr(),
            onPressed: () {
              final code = _controller.text.trim();
              if (code.isEmpty) return;
              widget.onJoin(code);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Shared padding / grabber wrapper so both sheets read as one component.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `showAppBottomSheet` already lifts the sheet above the keyboard, so the
    // shell only needs its own horizontal / bottom breathing room.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title.text(18, 24, 600).c(context.colors.textStrong),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
