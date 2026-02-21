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
  final bool isAdmin;
  final String userName;

  const TaskList({
    super.key,
    required this.workplaceId,
    required this.filter,
    required this.isAdmin,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final wpService = Provider.of<WorkplaceService>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<TaskItem>>(
      stream: wpService.getTasksStream(workplaceId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error Loading Tasks',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading tasks...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        final allTasks = snapshot.data ?? [];
        if (allTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Tasks Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasks will appear here once created by admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter
        final tasks = allTasks.where((t) {
          final isCompleted = t.completedBy != null;
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      filter == TaskFilter.completed
                          ? Icons.check_circle_outline
                          : Icons.pending_actions_outlined,
                      size: 64,
                      color: filter == TaskFilter.completed
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    filter == TaskFilter.completed
                        ? 'All Caught Up!'
                        : 'No Pending Tasks',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filter == TaskFilter.completed
                        ? 'You haven\'t completed any tasks yet'
                        : 'Great work! All tasks are completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
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
                  isAdmin: isAdmin,
                  userName: userName,
                )
                .animate()
                .slideX(duration: 300.ms, delay: (50 * index).ms)
                .fadeIn();
          },
        );
      },
    );
  }
}
