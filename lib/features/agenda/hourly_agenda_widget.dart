import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_role.dart';

class HourlyAgendaWidget extends StatefulWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final ThemeController themeController;
  final ValueChanged<Task>? onTaskTap;

  const HourlyAgendaWidget({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.themeController,
    this.onTaskTap,
  });

  @override
  State<HourlyAgendaWidget> createState() => _HourlyAgendaWidgetState();
}

class _HourlyAgendaWidgetState extends State<HourlyAgendaWidget> {
  TaskRole? _selectedRoleFilter;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late ScrollController _scrollController;

  static const double _hourHeight = 64.0;
  static const int _startHour = 6;
  static const int _endHour = 23;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToRelevantTime();
    });
  }

  void _scrollToRelevantTime() {
    if (!_scrollController.hasClients) return;
    final targetHour = widget.tasks.isNotEmpty
        ? widget.tasks.first.startTime.hour
        : _now.hour;
    final clampedHour = (targetHour - _startHour).clamp(0, _endHour - _startHour);
    final targetOffset = clampedHour * _hourHeight;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<Task> get _filteredTasks {
    if (_selectedRoleFilter == null) return widget.tasks;
    return widget.tasks.where((t) => t.role == _selectedRoleFilter).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.themeController.getColor('surface');
    final mutedColor = widget.themeController.getColor('muted');
    final rulesColor = widget.themeController.getColor('rules');

    final isToday = _isSameDay(widget.selectedDate, _now);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: rulesColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: rulesColor.withValues(alpha: 0.5))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  for (final role in TaskRole.values)
                    _buildFilterChip(role.displayName, role),
                ],
              ),
            ),
          ),

          // Hourly Timeline Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const totalHours = _endHour - _startHour + 1;
                final contentHeight = totalHours * _hourHeight;

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: contentHeight,
                    child: Stack(
                      children: [
                        // Background Hour Grid Lines & Labels
                        for (var i = 0; i < totalHours; i++) ...[
                          Positioned(
                            top: i * _hourHeight,
                            left: 0,
                            right: 0,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      '${(_startHour + i).toString().padLeft(2, '0')}:00',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedColor.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: rulesColor.withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Tasks Layout (Overlapping support)
                        Positioned.fill(
                          left: 50,
                          right: 8,
                          child: _buildTasksStack(),
                        ),

                        // Real-time Current Clock Line (Red line with circle)
                        if (isToday && _now.hour >= _startHour && _now.hour <= _endHour)
                          _buildCurrentTimeIndicator(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskRole? role) {
    final isSelected = _selectedRoleFilter == role;
    final accentColor = widget.themeController.getColor('accent');

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedRoleFilter = role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? (role?.color ?? accentColor).withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (role?.color ?? accentColor)
                  : widget.themeController.getColor('rules').withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (role != null) ...[
                Icon(role.icon, size: 12, color: role.color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? widget.themeController.getColor('text')
                      : widget.themeController.getColor('muted'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final minutesFromStart = (_now.hour - _startHour) * 60 + _now.minute;
    final topOffset = (minutesFromStart / 60.0) * _hourHeight;

    return Positioned(
      top: topOffset,
      left: 2,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.clockLine,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.clockLine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksStack() {
    final tasks = _filteredTasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    final layoutGroups = _calculateOverlapLayout(tasks);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          children: layoutGroups.map((item) {
            final task = item.task;
            final startMinutes =
                (task.startTime.hour - _startHour) * 60 + task.startTime.minute;
            final durationMinutes =
                task.endTime.difference(task.startTime).inMinutes.clamp(30, 240);

            final top = (startMinutes / 60.0) * _hourHeight;
            final height = (durationMinutes / 60.0) * _hourHeight - 4;
            final colWidth = totalWidth / item.totalColumns;
            final left = item.columnIndex * colWidth;

            return Positioned(
              top: top,
              left: left + 2,
              width: colWidth - 4,
              height: height,
              child: _TaskCard(
                task: task,
                themeController: widget.themeController,
                onTap: () => widget.onTaskTap?.call(task),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<_TaskLayoutInfo> _calculateOverlapLayout(List<Task> tasks) {
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<_TaskLayoutInfo> result = [];
    final List<List<Task>> columns = [];

    for (final task in sorted) {
      var placed = false;
      for (var col = 0; col < columns.length; col++) {
        final lastInCol = columns[col].last;
        if (task.startTime.isAfter(lastInCol.endTime) ||
            task.startTime.isAtSameMomentAs(lastInCol.endTime)) {
          columns[col].add(task);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([task]);
      }
    }

    final totalCols = columns.length.clamp(1, 4);

    for (var col = 0; col < columns.length; col++) {
      for (final t in columns[col]) {
        result.add(
          _TaskLayoutInfo(
            task: t,
            columnIndex: col,
            totalColumns: totalCols,
          ),
        );
      }
    }

    return result;
  }
}

class _TaskLayoutInfo {
  final Task task;
  final int columnIndex;
  final int totalColumns;

  const _TaskLayoutInfo({
    required this.task,
    required this.columnIndex,
    required this.totalColumns,
  });
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final ThemeController themeController;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.task,
    required this.themeController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = task.role.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? roleColor.withValues(alpha: 0.12)
        : roleColor.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeController.getColor('text'),
                            ),
                          ),
                        ),
                        Icon(task.role.icon, size: 13, color: roleColor),
                        const SizedBox(width: 4),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          task.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: themeController
                                .getColor('text')
                                .withValues(alpha: 0.75),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
