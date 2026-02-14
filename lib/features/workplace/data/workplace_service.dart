import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

class WorkplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create Workplace
  Future<String> createWorkplace(String adminId, String name) async {
    // Generate a simple 6-char ID for easier joining
    String workplaceId = _uuid.v4().substring(0, 6).toUpperCase();

    await _firestore.collection('workplaces').doc(workplaceId).set({
      'adminId': adminId,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [],
    });

    return workplaceId;
  }

  // Get Workplace Stream
  Stream<Workplace> getWorkplaceStream(String workplaceId) {
    return _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .snapshots()
        .map((doc) => Workplace.fromFirestore(doc));
  }

  // Add Task
  Future<void> addTask(
    String workplaceId,
    String title,
    String description,
    String? location,
    String? imageBase64,
  ) async {
    await _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .add({
          'title': title,
          'description': description,
          'location': location,
          'imageBase64': imageBase64,
          'createdAt': FieldValue.serverTimestamp(),
          'completedBy': null,
          'completedByName': null,
          'completionRemark': null,
        });
  }

  // Update Task
  Future<void> updateTask(
    String workplaceId,
    String taskId,
    String title,
    String description,
    String? location,
    String? imageBase64,
  ) async {
    await _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .doc(taskId)
        .update({
          'title': title,
          'description': description,
          'location': location,
          'imageBase64': imageBase64,
        });
  }

  // Tasks Stream
  Stream<List<TaskItem>> getTasksStream(String workplaceId) {
    return _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TaskItem.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Toggle Task Completion (Global)
  Future<void> toggleTaskCompletion(
    String workplaceId,
    String taskId,
    String userId,
    bool isDone,
    String userName, {
    String? completionRemark,
  }) async {
    final taskRef = _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .doc(taskId);

    if (isDone) {
      await taskRef.update({
        'completedBy': userId,
        'completedByName': userName,
        'completionRemark': completionRemark,
      });
    } else {
      await taskRef.update({
        'completedBy': null,
        'completedByName': null,
        'completionRemark': null,
      });
    }
  }

  // Delete Task
  Future<void> deleteTask(String workplaceId, String taskId) async {
    await _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Get Member Details
  Future<List<Map<String, dynamic>>> getMembersDetails(
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) return [];

    // Firestore 'in' query supports up to 10 items.
    // For simplicity, we fetch individually or in chunks.
    // Fetching individually for now to be safe with >10 members.
    List<Map<String, dynamic>> members = [];

    for (String id in memberIds) {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = id; // Add uid to data
        members.add(data);
      }
    }
    return members;
  }

  // Remove Member
  Future<void> removeMember(String workplaceId, String userId) async {
    // 1. Remove from workplace members list
    await _firestore.collection('workplaces').doc(workplaceId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    // 2. Clear workplaceId from user doc
    await _firestore.collection('users').doc(userId).update({
      'workplaceId': FieldValue.delete(),
    });
  }

  // Clear All Completed Tasks
  Future<void> clearAllCompletedTasks(String workplaceId) async {
    // Note: This only deletes completed tasks.
    final completedTasksSnapshot = await _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        // Firestore doesn't support where != null directly, so we check for where > '' or similar if string,
        // but since completedBy is a string or null, we can't easily query 'is not null' without an index or a specific sentinel.
        // However, a common trick is orderBy. 
        // Better approach: fetch all and filter client side if small, or add 'isCompleted' boolean field.
        // For now, we will just fetch all tasks and batch delete locally for simplicity in this small app.
        .get();

    final batch = _firestore.batch();
    for (var doc in completedTasksSnapshot.docs) {
      if (doc.data()['completedBy'] != null) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

}
