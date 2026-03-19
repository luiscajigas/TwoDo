import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Task>> getTodayTasks() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('tasks')
        .select()
        .eq('task_date', today)
        .order('created_at');
    return (response as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('task_date', ascending: false);
    return (response as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  // 👇 NUEVO: subir archivo a Storage y devolver URL pública
  Future<String?> uploadFile(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await _client.storage.from('task-files').upload(fileName, file);
    final publicUrl =
        _client.storage.from('task-files').getPublicUrl(fileName);
    return publicUrl;
  }

  @override
  Future<void> addTask(Task task) async {
    final model = TaskModel(
      id: '',
      title: task.title,
      description: task.description,
      scheduledTime: task.scheduledTime,
      category: task.category,
      isCompleted: task.isCompleted,
      taskDate: task.taskDate,
      fileUrl: task.fileUrl, // 👈 NUEVO
    );
    await _client.from('tasks').insert(model.toJson());
  }

  @override
  Future<void> toggleTask(String id, bool isCompleted) async {
    await _client
        .from('tasks')
        .update({'is_completed': isCompleted}).eq('id', id);
  }
}