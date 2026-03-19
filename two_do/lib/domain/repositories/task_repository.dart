import '../entities/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTodayTasks();
  Future<List<Task>> getAllTasks();
  Future<void> addTask(Task task);
  Future<void> toggleTask(String id, bool isCompleted);
}