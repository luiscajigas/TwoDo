import '../repositories/task_repository.dart';

class ToggleTask {
  final TaskRepository repository;
  ToggleTask(this.repository);
  Future<void> call(String id, bool isCompleted) =>
      repository.toggleTask(id, isCompleted);
}