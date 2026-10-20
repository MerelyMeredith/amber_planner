class DayDensity {
  final DateTime date;
  final double density; // Normalized between 0.0 (empty) and 1.0 (heavy)
  final int taskCount;

  const DayDensity({
    required this.date,
    required this.density,
    required this.taskCount,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'density': density,
    'taskCount': taskCount,
  };

  factory DayDensity.fromJson(Map<String, dynamic> json) {
    return DayDensity(
      date: DateTime.parse(json['date'] as String),
      density: (json['density'] as num).toDouble(),
      taskCount: json['taskCount'] as int,
    );
  }
}
