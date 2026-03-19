import 'package:flutter/material.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/toggle_task.dart';

class TaskProvider extends ChangeNotifier {
  final _repo = TaskRepositoryImpl();
  late final GetTodayTasks _getTodayTasks;
  late final GetAllTasks _getAllTasks;
  late final AddTask _addTask;
  late final ToggleTask _toggleTask;

  List<Task> todayTasks = [];
  List<Task> allTasks = [];
  bool isLoading = false;

  TaskProvider() {
    _getTodayTasks = GetTodayTasks(_repo);
    _getAllTasks = GetAllTasks(_repo);
    _addTask = AddTask(_repo);
    _toggleTask = ToggleTask(_repo);
    loadTodayTasks();
  }

  int get completedToday => todayTasks.where((t) => t.isCompleted).length;

  Future<void> loadTodayTasks() async {
    isLoading = true;
    notifyListeners();
    todayTasks = await _getTodayTasks();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllTasks() async {
    isLoading = true;
    notifyListeners();
    allTasks = await _getAllTasks();
    isLoading = false;
    notifyListeners();
  }

  Future<void> add(Task task) async {
    await _addTask(task);
    await loadTodayTasks();
  }

  Future<void> toggle(String id, bool value) async {
    await _toggleTask(id, value);
    await loadTodayTasks();
  }
}