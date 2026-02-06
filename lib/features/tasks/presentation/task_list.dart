import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';
import 'task_card.dart';

enum TaskFilter { all, pending, completed }

class TaskList extends StatelessWidget {
  final String workplaceId;
  final TaskFilter filter;

  const TaskList({
    super.key,
    required this.workplaceId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final wpService = Provider.of<WorkplaceService>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<TaskItem>>(
      stream: wpService.getTasksStream(workplaceId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTasks = snapshot.data ?? [];
        if (allTasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No tasks yet!'),
              ],
            ),
          );
        }

        // Filter
        final tasks = allTasks.where((t) {
          final isCompleted = t.completedBy.contains(uid);
          switch (filter) {
            case TaskFilter.all:
              return true;
            case TaskFilter.pending:
              return !isCompleted;
            case TaskFilter.completed:
              return isCompleted;
          }
        }).toList();

        if (tasks.isEmpty) {
           return const Center(child: Text("All caught up!"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              workplaceId: workplaceId,
              currentUserId: uid,
            ).animate().slideX(duration: 300.ms, delay: (50 * index).ms).fadeIn();
          },
        );
      },
    );
  }
}
