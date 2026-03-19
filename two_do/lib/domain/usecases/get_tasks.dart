import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTodayTasks {
  final TaskRepository repository;
  GetTodayTasks(this.repository);
  Future<List<Task>> call() => repository.getTodayTasks();
}

class GetAllTasks {
  final TaskRepository repository;
  GetAllTasks(this.repository);
  Future<List<Task>> call() => repository.getAllTasks();
}