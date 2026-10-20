import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../services/holiday_service.dart';
import '../settings/settings_panel.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, double> densities;
  final ThemeController themeController;
  final VoidCallback? onViewToggle;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.densities,
    required this.themeController,
    this.onViewToggle,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    _loadHolidays();
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        1,
      );
      _loadHolidays();
    }
  }

  Future<void> _loadHolidays() async {
    await HolidayService.instance.loadHolidaysForYear(_visibleMonth.year);
    if (mounted) setState(() {});
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
    _loadHolidays();
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
    _loadHolidays();
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _getDensity(DateTime day) {
    for (final entry in widget.densities.entries) {
      if (_isSameDay(entry.key, day)) {
        return entry.value;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = widget.themeController.getColor('surface');
    final textColor = widget.themeController.getColor('text');
    final mutedColor = widget.themeController.getColor('muted');
    final rulesColor = widget.themeController.getColor('rules');
    final accentColor = widget.themeController.getColor('accent');

    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final prevMonthLastDay = DateTime(year, month, 0).day;

    final startWeekday = firstDayOfMonth.weekday;
    final daysBefore = startWeekday - 1;

    final List<_DayCellModel> cells = [];

    // Preceding month days
    for (var i = daysBefore - 1; i >= 0; i--) {
      final day = prevMonthLastDay - i;
      cells.add(
        _DayCellModel(
          primaryDate: DateTime(year, month - 1, day),
          isCurrentMonth: false,
        ),
      );
    }

    // Current month days
    final overflowDays = <DateTime>[];
    for (var i = 1; i <= daysInMonth; i++) {
      final d = DateTime(year, month, i);
      if (cells.length < 35) {
        cells.add(_DayCellModel(primaryDate: d, isCurrentMonth: true));
      } else {
        overflowDays.add(d);
      }
    }

    // Fold any overflow days into week 5 (starting at cell index 28)
    for (var i = 0; i < overflowDays.length; i++) {
      final targetIndex = 28 + i;
      if (targetIndex < cells.length) {
        cells[targetIndex] = cells[targetIndex].copyWith(
          secondaryDate: overflowDays[i],
        );
      }
    }

    // Trailing next month days to make exactly 35 cells
    final remaining = 35 - cells.length;
    for (var i = 1; i <= remaining; i++) {
      cells.add(
        _DayCellModel(
          primaryDate: DateTime(year, month + 1, i),
          isCurrentMonth: false,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: rulesColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: rulesColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  tooltip: 'Preferences',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  onPressed: () =>
                      SettingsPanel.show(context, widget.themeController),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed: _prevMonth,
                      ),
                      Text(
                        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.view_agenda_outlined, size: 18),
                  tooltip: 'Toggle View',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  onPressed: widget.onViewToggle,
                ),
              ],
            ),
          ),

          // Weekday header
          Container(
            height: 22,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: rulesColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((
                d,
              ) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 5 Weeks Grid (Stretching across rows and columns to fill the full container height)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (rowIndex) {
                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (colIndex) {
                      final cellIndex = rowIndex * 7 + colIndex;
                      final cell = cells[cellIndex];

                      return Expanded(
                        child: _buildDayCell(
                          cell: cell,
                          theme: theme,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          rulesColor: rulesColor,
                          accentColor: accentColor,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required _DayCellModel cell,
    required ThemeData theme,
    required Color textColor,
    required Color mutedColor,
    required Color rulesColor,
    required Color accentColor,
  }) {
    if (cell.secondaryDate != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: rulesColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildSubCell(
                date: cell.primaryDate,
                isCurrentMonth: cell.isCurrentMonth,
                theme: theme,
                textColor: textColor,
                mutedColor: mutedColor,
                rulesColor: rulesColor,
                accentColor: accentColor,
              ),
            ),
            Container(height: 1, color: rulesColor.withValues(alpha: 0.3)),
            Expanded(
              child: _buildSubCell(
                date: cell.secondaryDate!,
                isCurrentMonth: true,
                theme: theme,
                textColor: textColor,
                mutedColor: mutedColor,
                rulesColor: rulesColor,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSubCell(
      date: cell.primaryDate,
      isCurrentMonth: cell.isCurrentMonth,
      theme: theme,
      textColor: textColor,
      mutedColor: mutedColor,
      rulesColor: rulesColor,
      accentColor: accentColor,
    );
  }

  Widget _buildSubCell({
    required DateTime date,
    required bool isCurrentMonth,
    required ThemeData theme,
    required Color textColor,
    required Color mutedColor,
    required Color rulesColor,
    required Color accentColor,
  }) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final density = _getDensity(date);
    final holiday = HolidayService.instance.findCachedHoliday(date);

    Color cellBackground = Colors.transparent;
    Color cellTextColor = isCurrentMonth
        ? textColor
        : mutedColor.withValues(alpha: 0.45);
    Border? cellBorder;

    if (isSelected) {
      cellBackground = AppColors.selectedDay;
      cellTextColor = Colors.white;
      cellBorder = Border.all(color: AppColors.selectedBorder, width: 2.0);
    } else if (!isCurrentMonth) {
      cellBackground = theme.brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.15)
          : const Color(0xFFE8EEF5);
    }

    Widget cellWidget = InkWell(
      onTap: () => widget.onDateSelected(date),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: cellBackground,
          border:
              cellBorder ??
              Border.all(color: rulesColor.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Holiday Indicator Dot (top right)
            if (holiday != null)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.holiday,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Day Number
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: cellTextColor,
              ),
            ),

            // Density Indicator Bar (reflecting actual entries)
            if (density > 0 && !isSelected)
              Positioned(
                bottom: 3,
                child: Container(
                  width: (22.0 * density).clamp(6.0, 24.0),
                  height: 2.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.25),
                    color: accentColor.withValues(
                      alpha: (0.45 + density * 0.55).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (holiday != null) {
      return Tooltip(message: holiday.name, child: cellWidget);
    }

    return cellWidget;
  }
}

class _DayCellModel {
  final DateTime primaryDate;
  final DateTime? secondaryDate;
  final bool isCurrentMonth;

  const _DayCellModel({
    required this.primaryDate,
    this.secondaryDate,
    required this.isCurrentMonth,
  });

  _DayCellModel copyWith({
    DateTime? primaryDate,
    DateTime? secondaryDate,
    bool? isCurrentMonth,
  }) {
    return _DayCellModel(
      primaryDate: primaryDate ?? this.primaryDate,
      secondaryDate: secondaryDate ?? this.secondaryDate,
      isCurrentMonth: isCurrentMonth ?? this.isCurrentMonth,
    );
  }
}
