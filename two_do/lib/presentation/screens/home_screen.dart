import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _green = Color(0xFF2ECC8F);

  Color _timeColor(String? time) {
    if (time == null) return const Color(0xFFE8F8F1);
    if (time.contains('8') || time.contains('6'))
      return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F8F1);
  }

  Color _timeTextColor(String? time) {
    if (time == null) return _green;
    if (time.contains('8') || time.contains('6'))
      return const Color(0xFFF5A623);
    return _green;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.todayTasks;
        final completed = provider.completedToday;
        final total = tasks.length;
        final progress = total == 0 ? 0.0 : completed / total;

        return SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: _green,
                onRefresh: provider.loadTodayTasks,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weekly card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 10,
                                            backgroundColor: Color(0xFFE8F8F1),
                                            valueColor: AlwaysStoppedAnimation(
                                              _green,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Weekly Tasks',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _statBox(total.toString(), false),
                                            const SizedBox(width: 8),
                                            _statBox(
                                              (total - completed).toString(),
                                              true,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Today Tasks header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today Tasks',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  '$completed of $total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE8F8F1),
                                valueColor: const AlwaysStoppedAnimation(
                                  _green,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    if (provider.isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: _green),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _TaskCard(
                              task: tasks[i],
                              timeColor: _timeColor(tasks[i].scheduledTime),
                              timeTextColor: _timeTextColor(
                                tasks[i].scheduledTime,
                              ),
                              onToggle: (val) =>
                                  provider.toggle(tasks[i].id, val),
                            ),
                            childCount: tasks.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 800,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<TaskProvider>(),
                          child: const AddTaskScreen(),
                        ),
                      ),
                    );
                  },
                  backgroundColor: _green,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String value, bool isRed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRed ? Colors.red.shade200 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isRed ? Colors.red : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final Color timeColor;
  final Color timeTextColor;
  final ValueChanged<bool> onToggle;

  const _TaskCard({
    required this.task,
    required this.timeColor,
    required this.timeTextColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!task.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? const Color(0xFF2ECC8F)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? const Color(0xFF2ECC8F)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: Colors.grey,
              ),
            ),
          ),
          if (task.scheduledTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: timeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.scheduledTime!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timeTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
