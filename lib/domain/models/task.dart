import 'task_role.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final TaskRole role;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.role,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    TaskRole? role,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      role: role ?? this.role,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'role': role.name,
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      role: TaskRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => TaskRole.personal,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
