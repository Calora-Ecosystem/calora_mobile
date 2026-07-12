import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A horizontally swipeable week calendar.
///
/// The row shows one week at a time (Mon–Sun). Swiping right walks back
/// through previous weeks — unbounded into the past — while the current week
/// is the forward limit (you can't log meals for the future). A slim header
/// tracks the visible month and offers a one-tap jump back to today.
///
/// The day-cell design (size, colours, selected pill) is unchanged from the
/// original static week strip; only navigation is added on top.
class WeekDaysSelector extends StatefulWidget {
  final ValueChanged<DateTime> onDaySelected;

  const WeekDaysSelector({super.key, required this.onDaySelected});

  @override
  State<WeekDaysSelector> createState() => _WeekDaysSelectorState();
}

class _WeekDaysSelectorState extends State<WeekDaysSelector> {
  // A large page budget so the past feels "infinite" without an unbounded
  // controller. The last page is always the current week (the forward limit).
  static const int _pageCount = 1000;
  static const int _initialPage = _pageCount - 1;

  late final PageController _controller;
  late final DateTime _today;
  late final DateTime _currentWeekStart;

  late DateTime _selectedDate;
  int _visiblePage = _initialPage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    // Monday as the first day of the week, matching the previous behaviour.
    _currentWeekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _selectedDate = _today;
    _controller = PageController(initialPage: _initialPage);

    // Preserve the original contract: emit today's date once mounted so the
    // page can load its initial data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDaySelected(_today);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _weekStartForPage(int page) =>
      _currentWeekStart.add(Duration(days: (page - _initialPage) * 7));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isFutureDay(DateTime day) =>
      DateTime(day.year, day.month, day.day).isAfter(_today);

  void _onDayTap(DateTime day) {
    if (_isFutureDay(day)) return;
    setState(() => _selectedDate = day);
    widget.onDaySelected(day);
  }

  void _jumpToToday() {
    setState(() => _selectedDate = _today);
    widget.onDaySelected(_today);
    if (_visiblePage != _initialPage) {
      _controller.animateToPage(
        _initialPage,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Label from the middle of the visible week so a week that straddles two
    // months reads as its dominant one.
    final labelDate = _weekStartForPage(_visiblePage).add(const Duration(days: 3));
    final monthLabel = DateFormat('MMMM yyyy').format(labelDate);
    final showTodayChip = _visiblePage != _initialPage || !_isSameDay(_selectedDate, _today);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              monthLabel.text(14, 18, 600).c(context.colors.textStrong),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showTodayChip ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showTodayChip,
                  child: GestureDetector(
                    onTap: _jumpToToday,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.lightGreen,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today_rounded,
                            size: 13,
                            color: context.colors.accentSub,
                          ),
                          const SizedBox(width: 4),
                          'today'.tr().text(12, 14, 600).c(context.colors.accentSub),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (page) => setState(() => _visiblePage = page),
            itemBuilder: (context, page) {
              final weekStart = _weekStartForPage(page);
              return Row(
                children: List.generate(7, (i) {
                  final day = weekStart.add(Duration(days: i));
                  return Expanded(child: _dayCell(context, day));
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final dayName = DateFormat('EEE').format(day);
    final dayNumber = DateFormat('d').format(day);
    final isSelected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, _today);
    final isDisabled = _isFutureDay(day);

    return GestureDetector(
      onTap: () => _onDayTap(day),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 46,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.accentSub : context.colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSelected
                ? Border.all(color: context.colors.accentSub, width: 1.4)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dayName.text(12, 14, 500).c(
                    isDisabled
                        ? context.colors.lightGray
                        : isSelected
                            ? context.colors.white
                            : context.colors.textSub,
                  ),
              const SizedBox(height: 2),
              dayNumber.text(14, 16, 600).c(
                    isDisabled
                        ? context.colors.lightGray
                        : isSelected
                            ? context.colors.white
                            : context.colors.textStrong,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
