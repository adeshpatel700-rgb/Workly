import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';
import 'add_task_screen.dart';
import 'task_details_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final String workplaceId;
  final String currentUserId;
  final bool isAdmin;
  final String userName;

  const TaskCard({
    super.key,
    required this.task,
    required this.workplaceId,
    required this.currentUserId,
    required this.isAdmin,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.completedBy != null;
    final completedByName = task.completedByName ?? 'Unknown';
    final isMyCompletion = task.completedBy == currentUserId;

    // canInteract only gates the checkbox (undo action) — NOT navigation.
    // Anyone can tap the card to view details.
    final canUndo = isAdmin || isMyCompletion;

    final service = Provider.of<WorkplaceService>(context, listen: false);

    return Dismissible(
      key: Key(task.id),
      direction: isAdmin
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        service.deleteTask(workplaceId, task.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? Colors.grey.shade50 : Colors.white,
        elevation: isDone ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDone
                ? Colors.grey.shade300
                : AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailsScreen(
                  task: task,
                  workplaceId: workplaceId,
                  isAdmin: isAdmin,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.task.imageBase64 != null &&
                    widget.task.imageBase64!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.memory(
                        base64Decode(widget.task.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (task.imageBase64 != null) const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationThickness: 2,
                                  color: isDone
                                      ? Colors.grey.shade500
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDone
                                      ? Colors.grey.shade400
                                      : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.location != null &&
                              task.location!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      task.location!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // EDIT BUTTON
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTaskScreen(
                                workplaceId: workplaceId,
                                taskToEdit: task,
                              ),
                            ),
                          );
                        },
                      ),
                    Transform.scale(
                      scale: 1.3,
                      child: Checkbox(
                        value: isDone,
                        activeColor: AppColors.success,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(
                          color: isDone
                              ? AppColors.success
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        onChanged: (!isDone || canUndo)
                            ? (val) async {
                                HapticFeedback.mediumImpact();
                                if (val == null) return;

                                String? remark;

                                // Show dialog with optional remark field when marking as done
                                final result = await showDialog<Map<String, dynamic>?>(
                                  context: context,
                                  builder: (ctx) {
                                    final remarkController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: Text(
                                        val
                                            ? 'Mark as Done?'
                                            : 'Mark as Pending?',
                                      ),
                                      content: val
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'This will mark the task as completed for everyone.',
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Add a remark (optional):',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: remarkController,
                                                  maxLines: 3,
                                                  maxLength: 200,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'e.g., Finished ahead of schedule',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'This will revert the task status for everyone.',
                                            ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, null),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, {
                                            'confirm': true,
                                            'remark': remarkController.text
                                                .trim(),
                                          }),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (result != null &&
                                    result['confirm'] == true) {
                                  remark = result['remark']?.isEmpty == true
                                      ? null
                                      : result['remark'];

                                  service.toggleTaskCompletion(
                                    workplaceId,
                                    task.id,
                                    currentUserId,
                                    val,
                                    userName.isEmpty ? 'Unknown' : userName,
                                    completionRemark: remark,
                                  );
                                }
                              }
                            : null, // Disable if not allowed
                      ),
                    ),
                  ],
                ),

                if (isDone) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Completed by $completedByName',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (task.completionRemark != null &&
                            task.completionRemark!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.comment,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.completionRemark!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                // --- Posted On ---
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Posted on ${DateFormat('MMM d, y').format(task.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
