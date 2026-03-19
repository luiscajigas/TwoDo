import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    super.scheduledTime,
    required super.category,
    required super.isCompleted,
    required super.taskDate,
    super.fileUrl, // 👈 NUEVO
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledTime: json['scheduled_time'],
      category: json['category'] ?? 'General',
      isCompleted: json['is_completed'] ?? false,
      taskDate: DateTime.parse(json['task_date']),
      fileUrl: json['file_url'], // 👈 NUEVO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'scheduled_time': scheduledTime,
      'category': category,
      'is_completed': isCompleted,
      'task_date': taskDate.toIso8601String().split('T')[0],
      'file_url': fileUrl, // 👈 NUEVO
    };
  }
}