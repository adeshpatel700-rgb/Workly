import 'package:cloud_firestore/cloud_firestore.dart';

class Workplace {
  final String id;
  final String adminId;
  final String name; 
  final List<String> members;

  Workplace({
    required this.id,
    required this.adminId, 
    required this.name,
    required this.members,
  });

  factory Workplace.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Workplace(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String? imageBase64;
  final String? location;
  final DateTime createdAt;
  final List<String> completedBy; // List of User IDs who completed this

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageBase64,
    this.location,
    required this.createdAt,
    required this.completedBy,
  });

  factory TaskItem.fromMap(String id, Map<String, dynamic> data) {
    return TaskItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageBase64: data['imageBase64'],
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedBy: List<String>.from(data['completedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageBase64': imageBase64,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'completedBy': completedBy,
    };
  }
}
