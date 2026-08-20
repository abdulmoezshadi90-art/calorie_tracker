import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';

/// Bottom sheet calendar for jumping to any day — replaces the old
/// tap-to-reset-to-today behavior of the Home screen's Today pill. Today
/// always gets the same glowing gold treatment the week strip already
/// uses for its selected day; the day currently being viewed (if it isn't
/// today) gets a thin accent ring instead, so the two states never read
/// as the same thing.
void showDatePickerSheet({required BuildContext context}) {
  final c = AppColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _DatePickerSheet(),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet();

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _viewedMonth;

  @override
  void initState() {
    super.initState();
    final selected = AppScope.read(context).selectedDate;
    _viewedMonth = DateTime(selected.year, selected.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final now = state.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = state.selectedDate;

    final firstOfMonth = DateTime(_viewedMonth.year, _viewedMonth.month);
    final daysInMonth = DateTime(
      _viewedMonth.year,
      _viewedMonth.month + 1,
      0,
    ).day;
    // Monday-first grid, matching the week strip's own convention
    // (home_screen.dart's _WeekStrip).
    final leadingBlanks = firstOfMonth.weekday - 1;
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_viewedMonth.year, _viewedMonth.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    void jumpTo(DateTime day) {
      Navigator.of(context).pop();
      state.selectDate(day);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              // Chevrons stay fixed (left = earlier, right = later)
              // regardless of the app's RTL state — Gregorian calendar
              // month navigation isn't mirrored in Arabic in practice
              // (same convention Google Calendar and WhatsApp use), so
              // flipping it here would be the actually-surprising choice.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(Icons.chevron_left, color: c.ink),
                ),
                Text(
                  l.monthYear(_viewedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(Icons.chevron_right, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        l.dayShort(monday.add(Duration(days: i))),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var row = 0; row < cells.length ~/ 7; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _DayCell(
                        day: cells[row * 7 + col],
                        today: today,
                        selected: selected,
                        onTap: jumpTo,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.selected,
    required this.onTap,
  });
  final DateTime? day;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final day = this.day;
    if (day == null) return const SizedBox(height: 44);

    final isToday = AppState.dateKey(day) == AppState.dateKey(today);
    final isSelected = AppState.dateKey(day) == AppState.dateKey(selected);
    final isFuture = day.isAfter(today);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? c.daySelectedBg : Colors.transparent,
            border: (!isToday && isSelected)
                ? Border.all(color: c.accent, width: 1.5)
                : null,
            // Same glow the week strip uses for its selected day — here
            // it marks today specifically, not whatever's selected.
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: c.daySelectedBg.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onTap(day),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday
                        ? c.daySelectedText
                        : c.ink.withValues(alpha: isFuture ? 0.4 : 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
