import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Listens to the real-time task stream for a given workplace.
/// Fires a local notification when a brand-new task is detected.
/// Skips notifications if the current user is an admin (they posted the task).
class TaskNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;
  
  // Tracks the IDs we've already seen to detect truly new tasks.
  final Set<String> _knownTaskIds = {};
  
  // Whether this notifier has been seeded with the initial snapshot yet.
  // We skip the first snapshot to avoid notifying for pre-existing tasks on app start.
  bool _initialSnapshotConsumed = false;
  
  // Whether the current user is the admin. Admins don't get notified.
  bool _isAdmin = false;

  /// Start listening for new tasks.
  /// Call this once the workplaceId and user role is known.
  void startListening({required String workplaceId, required bool isAdmin}) {
    _isAdmin = isAdmin;
    _subscription?.cancel();
    _knownTaskIds.clear();
    _initialSnapshotConsumed = false;

    _subscription = _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) => _handleSnapshot(snapshot));
  }

  void _handleSnapshot(QuerySnapshot snapshot) {
    final incomingIds = snapshot.docs.map((d) => d.id).toSet();

    if (!_initialSnapshotConsumed) {
      // Seed known IDs with what already exists — don't notify for any of these.
      _knownTaskIds.addAll(incomingIds);
      _initialSnapshotConsumed = true;
      return;
    }

    // Find truly new IDs
    final newIds = incomingIds.difference(_knownTaskIds);

    if (newIds.isNotEmpty && !_isAdmin) {
      for (final id in newIds) {
        final doc = snapshot.docs.firstWhere((d) => d.id == id);
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'New Task';
        final description = data['description'] as String? ?? '';

        NotificationService.instance.showNewTaskNotification(
          title: title,
          description: description,
        );
      }
    }

    // Update known IDs for next diff
    _knownTaskIds
      ..clear()
      ..addAll(incomingIds);
  }

  /// Stop listening. Call on logout or when no longer needed.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _knownTaskIds.clear();
    _initialSnapshotConsumed = false;
  }

  void dispose() => stopListening();
}
