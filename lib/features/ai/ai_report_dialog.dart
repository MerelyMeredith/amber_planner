import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../domain/models/ai_report.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_role.dart';

class AiReportDialog extends StatefulWidget {
  final AiExtractionReport report;
  final ThemeController themeController;
  final ValueChanged<List<Task>> onCommit;

  const AiReportDialog({
    super.key,
    required this.report,
    required this.themeController,
    required this.onCommit,
  });

  static Future<void> show({
    required BuildContext context,
    required AiExtractionReport report,
    required ThemeController themeController,
    required ValueChanged<List<Task>> onCommit,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AiReportDialog(
          report: report,
          themeController: themeController,
          onCommit: onCommit,
        );
      },
    );
  }

  @override
  State<AiReportDialog> createState() => _AiReportDialogState();
}

class _AiReportDialogState extends State<AiReportDialog> {
  late List<_EditableProposedTask> _editableTasks;

  @override
  void initState() {
    super.initState();
    _editableTasks = widget.report.proposedTasks
        .map((t) => _EditableProposedTask(
              task: t,
              titleController: TextEditingController(text: t.title),
              selectedRole: t.role,
              isSelected: true,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final item in _editableTasks) {
      item.titleController.dispose();
    }
    super.dispose();
  }

  void _commit() {
    final selectedTasks = _editableTasks
        .where((item) => item.isSelected)
        .map((item) => item.task.copyWith(
              title: item.titleController.text.trim().isEmpty
                  ? item.task.title
                  : item.titleController.text.trim(),
              role: item.selectedRole,
            ))
        .toList();

    widget.onCommit(selectedTasks);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.themeController.getColor('text');
    final accentColor = widget.themeController.getColor('accent');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 580,
        height: 520,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Local AI Extraction Report'),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Badge & Summary Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 20, color: accentColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.report.summary,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'REVIEW & EDIT EXTRACTED TASKS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                    color: widget.themeController.getColor('muted'),
                  ),
                ),
                const SizedBox(height: 8),

                // Editable Tasks List
                Expanded(
                  child: ListView.separated(
                    itemCount: _editableTasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _editableTasks[index];
                      final role = item.selectedRole;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.isSelected
                                ? role.color.withValues(alpha: 0.5)
                                : widget.themeController.getColor('rules'),
                          ),
                          color: item.isSelected
                              ? role.color.withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: item.isSelected,
                              activeColor: role.color,
                              onChanged: (val) {
                                setState(() {
                                  item.isSelected = val ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: item.titleController,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                  Text(
                                    '${item.task.startTime.hour.toString().padLeft(2, '0')}:${item.task.startTime.minute.toString().padLeft(2, '0')} - ${item.task.endTime.hour.toString().padLeft(2, '0')}:${item.task.endTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.themeController.getColor('muted'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Role selector dropdown
                            DropdownButton<TaskRole>(
                              value: item.selectedRole,
                              underline: const SizedBox.shrink(),
                              isDense: true,
                              items: TaskRole.values.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Row(
                                    children: [
                                      Icon(r.icon, size: 14, color: r.color),
                                      const SizedBox(width: 6),
                                      Text(
                                        r.displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: r.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newRole) {
                                if (newRole != null) {
                                  setState(() {
                                    item.selectedRole = newRole;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(
                        'Accept & Add (${_editableTasks.where((i) => i.isSelected).length})',
                      ),
                      onPressed: _editableTasks.any((i) => i.isSelected)
                          ? _commit
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableProposedTask {
  final Task task;
  final TextEditingController titleController;
  TaskRole selectedRole;
  bool isSelected;

  _EditableProposedTask({
    required this.task,
    required this.titleController,
    required this.selectedRole,
    required this.isSelected,
  });
}
