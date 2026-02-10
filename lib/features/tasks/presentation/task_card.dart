import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';
import '../../auth/data/auth_service.dart';

class TaskCard extends StatefulWidget {
  final TaskItem task;
  final String workplaceId;
  final String currentUserId;

  const TaskCard({
    super.key,
    required this.task,
    required this.workplaceId,
    required this.currentUserId,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool? _isAdmin;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkRoleAndName();
  }

  void _checkRoleAndName() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    final role = await auth.getUserRole();
    final name = prefs.getString('userName') ?? 'Unknown';
    
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
        _userName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // New Logic: Completed if completedBy is not null
    final isDone = widget.task.completedBy != null;
    final completedByName = widget.task.completedByName ?? 'Unknown';
    final isMyCompletion = widget.task.completedBy == widget.currentUserId;
    
    // Interaction Rules:
    // - If not done: Anyone can do it.
    // - If done: Only Admin or the Completer can undo.
    final canInteract = !isDone || (_isAdmin == true || isMyCompletion);

    final service = Provider.of<WorkplaceService>(context, listen: false);

    return Dismissible(
      key: Key(widget.task.id),
      direction: _isAdmin == true ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        service.deleteTask(widget.workplaceId, widget.task.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: AppColors.taskCardBackground, // New Calm Color
        elevation: 0, // Flat look request
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // View details? optional
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.task.imageBase64 != null && widget.task.imageBase64!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Image.memory(
                        base64Decode(widget.task.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                if (widget.task.imageBase64 != null) const SizedBox(height: 12),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.task.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.task.location != null && widget.task.location!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.task.location!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isDone,
                        activeColor: AppColors.success,
                        shape: const CircleBorder(),
                        onChanged: canInteract ? (val) async {
                          if (val == null) return;
                          
                          // Optional: Confirm dialog for marking done/undone
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(val ? 'Mark as Done?' : 'Mark as Pending?'),
                              content: Text(val 
                                ? 'This will mark the task as completed for everyone.' 
                                : 'This will revert the task status for everyone.'
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            service.toggleTaskCompletion(
                              widget.workplaceId,
                              widget.task.id,
                              widget.currentUserId,
                              val,
                              _userName ?? 'Unknown',
                            );
                          }
                        } : null, // Disable if not allowed
                      ),
                    ),
                  ],
                ),
                
                if (isDone) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Completed by $completedByName',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
