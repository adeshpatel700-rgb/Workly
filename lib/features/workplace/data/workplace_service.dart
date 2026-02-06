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
    return _firestore.collection('workplaces').doc(workplaceId).snapshots().map(
      (doc) => Workplace.fromFirestore(doc)
    );
  }

  // Add Task
  Future<void> addTask(String workplaceId, String title, String description, String? location, String? imageBase64) async {
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
      'completedBy': [],
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

  // Toggle Task Completion
  Future<void> toggleTaskCompletion(String workplaceId, String taskId, String userId, bool isDone) async {
    final taskRef = _firestore
        .collection('workplaces')
        .doc(workplaceId)
        .collection('tasks')
        .doc(taskId);

    if (isDone) {
      await taskRef.update({
        'completedBy': FieldValue.arrayUnion([userId])
      });
    } else {
      await taskRef.update({
        'completedBy': FieldValue.arrayRemove([userId])
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
}
