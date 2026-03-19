class Task {
  final String id;
  final String title;
  final String? description;
  final String? scheduledTime;
  final String category;
  final bool isCompleted;
  final DateTime taskDate;
  final String? fileUrl; // 👈 NUEVO

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.scheduledTime,
    required this.category,
    required this.isCompleted,
    required this.taskDate,
    this.fileUrl, // 👈 NUEVO
  });

  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      description: description,
      scheduledTime: scheduledTime,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      taskDate: taskDate,
      fileUrl: fileUrl,
    );
  }
}