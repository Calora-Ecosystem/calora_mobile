import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final double height;
  final String? initialTime;
  final bool isInterval;

  const TimePickerWidget({
    super.key,
    required this.onChanged,
    this.height = 138,
    this.initialTime,
    this.isInterval = false,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  // ── Interval mode ("every N hours") — a single wheel ────────────────
  FixedExtentScrollController? _intervalController;
  int _intervalIndex = 0;
  late final List<String> _intervalTimes;
  late final List<String> _intervalDisplay;

  // ── Exact-time mode — separate hour + minute wheels ─────────────────
  FixedExtentScrollController? _hourController;
  FixedExtentScrollController? _minuteController;
  int _selectedHour = 0;
  int _selectedMinute = 0;

  @override
  void initState() {
    super.initState();

    if (widget.isInterval) {
      _intervalTimes = List.generate(
        24,
        (i) => '${(i + 1).toString().padLeft(2, '0')}:00',
      ); // 01:00 to 24:00
      _intervalDisplay = List.generate(
        _intervalTimes.length,
        (i) => Strings.everyNHour(hour: i + 1),
      );
      _intervalIndex = _resolveIntervalIndex();
      _intervalController = FixedExtentScrollController(
        initialItem: _intervalIndex,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        var time = _intervalTimes[_intervalIndex];
        if (time == '24:00') time = '00:00';
        widget.onChanged(time);
      });
    } else {
      final (hour, minute) = _resolveInitialHourMinute();
      _selectedHour = hour;
      _selectedMinute = minute;
      _hourController = FixedExtentScrollController(initialItem: hour);
      _minuteController = FixedExtentScrollController(initialItem: minute);

      WidgetsBinding.instance.addPostFrameCallback((_) => _emitExact());
    }
  }

  void _emitExact() {
    final h = _selectedHour.toString().padLeft(2, '0');
    final m = _selectedMinute.toString().padLeft(2, '0');
    widget.onChanged('$h:$m');
  }

  /// Parses `initialTime` ("HH:mm") into hour/minute, defaulting to the
  /// current wall-clock time (including minutes) when nothing is provided.
  (int, int) _resolveInitialHourMinute() {
    if (widget.initialTime == null || widget.initialTime!.isEmpty) {
      final now = DateTime.now();
      return (now.hour, now.minute);
    }
    final parts = widget.initialTime!.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (hour.clamp(0, 23), minute.clamp(0, 59));
  }

  int _resolveIntervalIndex() {
    if (widget.initialTime == null) {
      final currentHour = DateTime.now().hour;
      if (currentHour == 0) return 23; // 00:00 maps to 24:00 (index 23)
      return (currentHour - 1).clamp(0, 23); // 01:00 (index 0) to 23:00
    }
    String cleaned = widget.initialTime!;
    if (cleaned.length > 5) {
      cleaned = cleaned.substring(0, 5);
    }

    if (cleaned == '00:00') {
      cleaned = '24:00'; // treat 00:00 as 24:00 for intervals
    }

    final index = _intervalTimes.indexOf(cleaned);
    return index != -1 ? index : 0;
  }

  @override
  void dispose() {
    _intervalController?.dispose();
    _hourController?.dispose();
    _minuteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: widget.isInterval
          ? _buildIntervalPicker(context)
          : _buildExactPicker(context),
    );
  }

  Widget _buildIntervalPicker(BuildContext context) {
    return CupertinoPicker(
      scrollController: _intervalController,
      itemExtent: 30,
      diameterRatio: 2,
      useMagnifier: true,
      magnification: 1.1,
      squeeze: 0.7,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: (index) {
        setState(() => _intervalIndex = index);
        String timeToReturn = _intervalTimes[index];
        if (timeToReturn == '24:00') timeToReturn = '00:00';
        widget.onChanged(timeToReturn);
      },
      children: _intervalDisplay
          .map(
            (value) => Center(
              child: value.text(24, 30, 400).c(context.colors.defaultText),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExactPicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _wheel(
          context,
          controller: _hourController!,
          count: 24,
          onSelected: (i) {
            setState(() => _selectedHour = i);
            _emitExact();
          },
        ),
        ':'.text(35, 44, 400).c(context.colors.defaultText),
        _wheel(
          context,
          controller: _minuteController!,
          count: 60,
          onSelected: (i) {
            setState(() => _selectedMinute = i);
            _emitExact();
          },
        ),
      ],
    );
  }

  Widget _wheel(
    BuildContext context, {
    required FixedExtentScrollController controller,
    required int count,
    required ValueChanged<int> onSelected,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 45,
        diameterRatio: 2,
        useMagnifier: true,
        magnification: 1.1,
        squeeze: 0.9,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: onSelected,
        children: List.generate(
          count,
          (i) => Center(
            child: i
                .toString()
                .padLeft(2, '0')
                .text(35, 44, 400)
                .c(context.colors.defaultText),
          ),
        ),
      ),
    );
  }
}
