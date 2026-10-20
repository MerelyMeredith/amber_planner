import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/chrono_helper.dart';
import '../../domain/models/task.dart';
import '../../services/planner_facade.dart';
import '../ai/ai_report_dialog.dart';
import '../settings/settings_panel.dart';
import 'chrono_note_controller.dart';
import 'ruled_notes.dart';

class NotesPanel extends StatefulWidget {
  final DateTime selectedDate;
  final PlannerFacade facade;
  final ThemeController themeController;
  final ValueChanged<DateTime>? onJumpToDate;
  final VoidCallback? onBookmarkTap;

  const NotesPanel({
    super.key,
    required this.selectedDate,
    required this.facade,
    required this.themeController,
    this.onJumpToDate,
    this.onBookmarkTap,
  });

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  late ChronoNoteController _textController;
  Timer? _saveDebounce;
  bool _isAiProcessing = false;
  List<ParsedDateSpan> _detectedDates = [];

  @override
  void initState() {
    super.initState();
    _textController = ChronoNoteController(
      highlightColor: widget.themeController.getColor('accent'),
    )..addListener(_updateDetectedDates);
    _loadNoteForDate(widget.selectedDate);
  }

  void _updateDetectedDates() {
    final parsed = _textController.detectedDates;
    if (mounted && _detectedDates != parsed) {
      setState(() {
        _detectedDates = parsed;
      });
    }
  }

  @override
  void didUpdateWidget(covariant NotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _saveDebounce?.cancel();
      _loadNoteForDate(widget.selectedDate);
    }
  }

  Future<void> _loadNoteForDate(DateTime date) async {
    final note = await widget.facade.loadNote(date);
    if (mounted) {
      _textController.text = note;
      _updateDetectedDates();
    }
  }

  void _onTextChanged(String text) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      widget.facade.saveNote(widget.selectedDate, text);
    });
  }

  Future<void> _triggerAiExtraction() async {
    if (_isAiProcessing) return;

    final raw = _textController.text;
    final sanitized = RuledNotes.sanitizeTextForAi(raw);

    if (sanitized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write some notes or todos first before running AI.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isAiProcessing = true);

    try {
      final report = await widget.facade.analyzeNotesWithAi(
        widget.selectedDate,
        sanitized,
      );

      if (!mounted) return;

      setState(() => _isAiProcessing = false);

      await AiReportDialog.show(
        context: context,
        report: report,
        themeController: widget.themeController,
        onCommit: (List<Task> approvedTasks) async {
          await widget.facade.commitAiProposals(
            widget.selectedDate,
            approvedTasks,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${approvedTasks.length} tasks to agenda.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted && _isAiProcessing) {
        setState(() => _isAiProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _textController.removeListener(_updateDetectedDates);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rulesColor = widget.themeController.getColor('rules');
    final surfaceColor = widget.themeController.getColor('surface');
    final accentColor = widget.themeController.getColor('accent');

    return Container(
      decoration: BoxDecoration(
        color: widget.themeController.getColor('background'),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: rulesColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Main Area: Ruled Notes + Detected Dates Banner
          Expanded(
            child: Column(
              children: [
                // Live Detected Dates Banner (via chrono_dart)
                if (_detectedDates.isNotEmpty)
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(
                        bottom: BorderSide(color: rulesColor.withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Detected Dates:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.themeController.getColor('muted'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _detectedDates.map((span) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                    avatar: const Icon(Icons.event, size: 12),
                                    label: Text(
                                      span.formattedLabel,
                                      style: const TextStyle(fontSize: 10.5),
                                    ),
                                    onPressed: () {
                                      widget.onJumpToDate?.call(span.dateTime);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ruled Notes Editor
                Expanded(
                  child: RuledNotes(
                    themeController: widget.themeController,
                    controller: _textController,
                    onChanged: _onTextChanged,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Action Rail on Far Right
          Container(
            width: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                left: BorderSide(color: rulesColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 22),
                  tooltip: 'Saved Notes',
                  onPressed: widget.onBookmarkTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notes Bookmark Index'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 12),

                // Lightning Bolt: Local AI Extraction
                IconButton(
                  icon: _isAiProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        )
                      : Icon(
                          Icons.bolt_outlined,
                          size: 24,
                          color: accentColor,
                        ),
                  tooltip: 'Local AI: Extract Tasks',
                  onPressed: _isAiProcessing ? null : _triggerAiExtraction,
                ),

                const Spacer(),

                // Menu / Preferences
                IconButton(
                  icon: const Icon(Icons.menu, size: 22),
                  tooltip: 'Preferences & Menu',
                  onPressed: () {
                    SettingsPanel.show(context, widget.themeController);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
