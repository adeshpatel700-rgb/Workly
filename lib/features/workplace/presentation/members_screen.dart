import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import 'package:workly/features/workplace/data/workplace_service.dart';
import 'package:workly/features/workplace/data/models.dart';

class MembersScreen extends StatelessWidget {
  final String workplaceId;

  const MembersScreen({super.key, required this.workplaceId});

  @override
  Widget build(BuildContext context) {
    final wpService = Provider.of<WorkplaceService>(context, listen: false);

    return StreamBuilder<Workplace>(
      stream: wpService.getWorkplaceStream(workplaceId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final workplace = snapshot.data!;
        final memberIds = workplace.members;

        return Scaffold(
          appBar: AppBar(title: Text('Team Members (${memberIds.length})')),
          body: _MembersList(
            workplaceId: workplaceId,
            memberIds: memberIds,
            adminId: workplace.adminId,
          ),
        );
      },
    );
  }
}

class _MembersList extends StatefulWidget {
  final String workplaceId;
  final List<String> memberIds;
  final String adminId;

  const _MembersList({
    required this.workplaceId,
    required this.memberIds,
    required this.adminId,
  });

  @override
  State<_MembersList> createState() => _MembersListState();
}

class _MembersListState extends State<_MembersList> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void didUpdateWidget(covariant _MembersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberIds.length != widget.memberIds.length ||
        !_listEquals(oldWidget.memberIds, widget.memberIds)) {
      _loadMembers();
    }
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _loadMembers() {
    final service = Provider.of<WorkplaceService>(context, listen: false);
    _membersFuture = service.getMembersDetails(widget.memberIds);
  }

  Future<void> _removeMember(String userId, String name) async {
    // Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('They will be removed immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Provider.of<WorkplaceService>(
          context,
          listen: false,
        ).removeMember(widget.workplaceId, userId);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name removed')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final members = snapshot.data ?? [];
        if (members.isEmpty)
          return const Center(child: Text('No members found.'));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final m = members[index];
            // Defensive casting: handle case where field might be List
            final nameRaw = m['name'];
            final name =
                (nameRaw is String
                    ? nameRaw
                    : (nameRaw is List && nameRaw.isNotEmpty
                          ? nameRaw[0]
                          : null)) ??
                'Unknown';
            final uidRaw = m['uid'];
            final uid =
                (uidRaw is String
                        ? uidRaw
                        : (uidRaw is List && uidRaw.isNotEmpty
                              ? uidRaw[0]
                              : 'unknown'))
                    as String;
            final isMe =
                uid ==
                widget
                    .adminId; // Assuming current user is admin if seeing this screen

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(uid == widget.adminId ? 'Admin (You)' : 'Member'),
              trailing: !isMe
                  ? IconButton(
                      icon: const Icon(
                        Icons.person_remove,
                        color: AppColors.error,
                      ),
                      onPressed: () => _removeMember(uid, name),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
