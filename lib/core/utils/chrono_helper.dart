import 'package:chrono_dart/chrono_dart.dart';

class ParsedDateSpan {
  final int startIndex;
  final int endIndex;
  final String matchedText;
  final DateTime dateTime;

  const ParsedDateSpan({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.dateTime,
  });

  String get formattedLabel {
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$matchedText ($m/$d $h:$min)';
  }
}

class ChronoHelper {
  /// Parses natural language dates from text using chrono_dart.
  static List<ParsedDateSpan> parseDates(String text, {DateTime? referenceDate}) {
    if (text.trim().isEmpty) return const [];

    try {
      final results = Chrono.parse(
        text,
        ref: referenceDate ?? DateTime.now(),
      );

      return results.map((r) {
        final start = r.index.toInt();
        final len = r.text.length;
        return ParsedDateSpan(
          startIndex: start,
          endIndex: start + len,
          matchedText: r.text,
          dateTime: r.date(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
