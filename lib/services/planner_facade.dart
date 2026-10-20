import '../domain/models/ai_report.dart';
import '../domain/models/task.dart';

abstract class PlannerFacade {
  Stream<List<Task>> watchTasks(DateTime date);
  Future<List<Task>> getTasks(DateTime date);
  Stream<Map<DateTime, double>> watchMonthDensities(int year, int month);
  Future<String> loadNote(DateTime date);
  Future<void> saveNote(DateTime date, String content);
  Future<AiExtractionReport> analyzeNotesWithAi(DateTime date, String notes);
  Future<void> commitAiProposals(DateTime date, List<Task> tasks);
  Future<void> addTask(Task task);
  Future<void> deleteTask(String id);
}
