import 'dart:async';
import '../domain/models/ai_report.dart';
import '../domain/models/task.dart';
import '../domain/models/task_role.dart';
import 'planner_facade.dart';

class MockPlannerFacade implements PlannerFacade {
  final Map<String, List<Task>> _tasksByDate = {};
  final Map<String, String> _notesByDate = {};

  final StreamController<Map<DateTime, double>> _densityController =
      StreamController<Map<DateTime, double>>.broadcast();

  final StreamController<void> _changeNotifier =
      StreamController<void>.broadcast();

  MockPlannerFacade() {
    _seedInitialData();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _seedInitialData() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    // Seed realistic tasks for TODAY
    _tasksByDate[todayKey] = [
      Task(
        id: 'seed_today_1',
        title: 'Project Architecture Review',
        description:
            'Finalize the decoupled facade architecture and verify zero technical debt before initial commit.',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 30),
        role: TaskRole.work,
      ),
      Task(
        id: 'seed_today_2',
        title: 'Deep Learning Seminar',
        description:
            'Review latent space representation and multi-agent systems literature.',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        role: TaskRole.academic,
      ),
      Task(
        id: 'seed_today_3',
        title: 'Coffee & Reflection',
        description: 'Read a chapter and write weekly personal goals.',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 15),
        role: TaskRole.personal,
      ),
      Task(
        id: 'seed_today_4',
        title: 'Community Release Note',
        description: 'Publish updates on the open source project repository.',
        startTime: DateTime(now.year, now.month, now.day, 16, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 15),
        role: TaskRole.world,
      ),
    ];

    // Seed starter note for TODAY with dates that chrono_dart will detect!
    _notesByDate[todayKey] =
        'Daily Focus - ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n\n'
        '- Meeting with team tomorrow at 10am\n'
        '- Finish documentation by Friday 5pm\n'
        '- Review publication next Monday at 2pm\n\n'
        'Notes & Log:\n'
        'The planner facade is now fully decoupled from local storage and offline AI pipelines.';

    // Seed tasks for tomorrow (1 task -> density ~0.33)
    final tomorrow = now.add(const Duration(days: 1));
    _tasksByDate[_dateKey(tomorrow)] = [
      Task(
        id: 'seed_tomorrow_1',
        title: 'Client Demo Sync',
        description: 'Demonstrate offline AI task extraction.',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0),
        role: TaskRole.work,
      ),
    ];

    // Seed tasks for 3 days from now (2 tasks -> density ~0.66)
    final futureDay = now.add(const Duration(days: 3));
    _tasksByDate[_dateKey(futureDay)] = [
      Task(
        id: 'seed_future_1',
        title: 'Study Session',
        description: 'Compiler construction lab.',
        startTime: DateTime(futureDay.year, futureDay.month, futureDay.day, 9, 0),
        endTime: DateTime(futureDay.year, futureDay.month, futureDay.day, 11, 0),
        role: TaskRole.academic,
      ),
      Task(
        id: 'seed_future_2',
        title: 'Gym & Fitness',
        description: 'Strength training.',
        startTime: DateTime(futureDay.year, futureDay.month, futureDay.day, 17, 0),
        endTime: DateTime(futureDay.year, futureDay.month, futureDay.day, 18, 30),
        role: TaskRole.personal,
      ),
    ];
  }

  @override
  Stream<List<Task>> watchTasks(DateTime date) async* {
    yield await getTasks(date);
    yield* _changeNotifier.stream.asyncMap((_) => getTasks(date));
  }

  @override
  Future<List<Task>> getTasks(DateTime date) async {
    final key = _dateKey(date);
    return List.unmodifiable(_tasksByDate[key] ?? []);
  }

  @override
  Stream<Map<DateTime, double>> watchMonthDensities(int year, int month) async* {
    yield _computeDensities(year, month);
    yield* _densityController.stream;
    yield* _changeNotifier.stream.map((_) => _computeDensities(year, month));
  }

  /// Calculates density purely based on the number of actual entries for that date:
  /// 0 entries -> 0.0
  /// 1 entry   -> 0.35
  /// 2 entries -> 0.70
  /// 3+ entries-> 1.00
  Map<DateTime, double> _computeDensities(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final map = <DateTime, double>{};

    for (var day = 1; day <= daysInMonth; day++) {
      final d = DateTime(year, month, day);
      final key = _dateKey(d);
      final tasks = _tasksByDate[key] ?? [];

      if (tasks.isEmpty) {
        map[d] = 0.0;
      } else if (tasks.length == 1) {
        map[d] = 0.35;
      } else if (tasks.length == 2) {
        map[d] = 0.70;
      } else {
        map[d] = 1.0;
      }
    }
    return map;
  }

  @override
  Future<String> loadNote(DateTime date) async {
    return _notesByDate[_dateKey(date)] ?? '';
  }

  @override
  Future<void> saveNote(DateTime date, String content) async {
    _notesByDate[_dateKey(date)] = content;
  }

  @override
  Future<AiExtractionReport> analyzeNotesWithAi(
    DateTime date,
    String notes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lines = notes.split('\n');
    final extractedTasks = <Task>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        final clean = trimmed.replaceFirst(RegExp(r'^[-*]\s*(\[[ x]\]\s*)?'), '');
        if (clean.isNotEmpty && clean.length > 3) {
          var role = TaskRole.personal;
          final lower = clean.toLowerCase();
          if (lower.contains('client') || lower.contains('work') || lower.contains('meeting')) {
            role = TaskRole.work;
          } else if (lower.contains('study') || lower.contains('read') || lower.contains('chapter') || lower.contains('lab')) {
            role = TaskRole.academic;
          } else if (lower.contains('release') || lower.contains('community') || lower.contains('public')) {
            role = TaskRole.world;
          }

          extractedTasks.add(
            Task(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${extractedTasks.length}',
              title: clean,
              description: 'Extracted by local AI on ${_dateKey(date)}',
              startTime: DateTime(date.year, date.month, date.day, 12 + extractedTasks.length * 2, 0),
              endTime: DateTime(date.year, date.month, date.day, 13 + extractedTasks.length * 2, 0),
              role: role,
            ),
          );
        }
      }
    }

    if (extractedTasks.isEmpty) {
      extractedTasks.add(
        Task(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}_1',
          title: 'Review today notes & organize todos',
          description: notes.length > 60 ? '${notes.substring(0, 60)}...' : notes,
          startTime: DateTime(date.year, date.month, date.day, 18, 0),
          endTime: DateTime(date.year, date.month, date.day, 19, 0),
          role: TaskRole.personal,
        ),
      );
    }

    return AiExtractionReport(
      date: date,
      summary: 'Extracted ${extractedTasks.length} task(s) from your notes for ${_dateKey(date)}.',
      proposedTasks: extractedTasks,
    );
  }

  @override
  Future<void> commitAiProposals(DateTime date, List<Task> tasks) async {
    final key = _dateKey(date);
    final current = _tasksByDate[key] ?? [];
    _tasksByDate[key] = [...current, ...tasks];

    _changeNotifier.add(null);
    _densityController.add(_computeDensities(date.year, date.month));
  }

  @override
  Future<void> addTask(Task task) async {
    final key = _dateKey(task.startTime);
    final current = _tasksByDate[key] ?? [];
    _tasksByDate[key] = [...current, task];

    _changeNotifier.add(null);
    _densityController.add(_computeDensities(task.startTime.year, task.startTime.month));
  }

  @override
  Future<void> deleteTask(String id) async {
    for (final entry in _tasksByDate.entries) {
      entry.value.removeWhere((t) => t.id == id);
    }
    _changeNotifier.add(null);
  }
}
