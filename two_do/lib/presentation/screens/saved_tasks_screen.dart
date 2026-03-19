import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../../domain/entities/task.dart';

class SavedTasksScreen extends StatefulWidget {
  const SavedTasksScreen({super.key});

  @override
  State<SavedTasksScreen> createState() => _SavedTasksScreenState();
}

class _SavedTasksScreenState extends State<SavedTasksScreen> {
  static const _green = Color(0xFF2ECC8F);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TaskProvider>().loadAllTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.allTasks;
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'All Tasks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: _green))
                    : RefreshIndicator(
                        color: _green,
                        onRefresh: provider.loadAllTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => _SavedTaskTile(task: tasks[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SavedTaskTile extends StatelessWidget {
  final Task task;
  const _SavedTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? const Color(0xFF2ECC8F) : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${task.category} · ${task.taskDate.day}/${task.taskDate.month}/${task.taskDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.isCompleted ? const Color(0xFFE8F8F1) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.isCompleted ? 'Done' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: task.isCompleted ? const Color(0xFF2ECC8F) : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}