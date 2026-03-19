import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  static const _green = Color(0xFF2ECC8F);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final all = provider.todayTasks;
        final completed = all.where((t) => t.isCompleted).length;
        final pending = all.length - completed;
        final progress = all.isEmpty ? 0.0 : completed / all.length;

        final Map<String, int> byCategory = {};
        for (final t in provider.allTasks) {
          byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 20),

                // Ring chart
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 16,
                          backgroundColor: const Color(0xFFE8F8F1),
                          valueColor: const AlwaysStoppedAnimation(_green),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(progress * 100).round()}%',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const Text('completed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    _statCard('Completed', completed.toString(), _green),
                    const SizedBox(width: 12),
                    _statCard('Pending', pending.toString(), Colors.orange),
                    const SizedBox(width: 12),
                    _statCard('Total', all.length.toString(), Colors.blueGrey),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ...byCategory.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text('${e.value} tasks', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}