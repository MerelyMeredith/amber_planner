import 'task.dart';

class AiExtractionReport {
  final DateTime date;
  final String summary;
  final List<Task> proposedTasks;
  final List<String> extractedNotes;

  const AiExtractionReport({
    required this.date,
    required this.summary,
    required this.proposedTasks,
    this.extractedNotes = const [],
  });

  AiExtractionReport copyWith({
    DateTime? date,
    String? summary,
    List<Task>? proposedTasks,
    List<String>? extractedNotes,
  }) {
    return AiExtractionReport(
      date: date ?? this.date,
      summary: summary ?? this.summary,
      proposedTasks: proposedTasks ?? this.proposedTasks,
      extractedNotes: extractedNotes ?? this.extractedNotes,
    );
  }
}
