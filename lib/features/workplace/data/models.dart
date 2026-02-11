import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to safely cast dynamic to String, handling List cases
String? _safeString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is List && value.isNotEmpty) return value[0]?.toString();
  return value.toString();
}

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
      adminId: _safeString(data['adminId']) ?? '',
      name: _safeString(data['name']) ?? '',
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
  final String? completedBy; // User ID of the completer
  final String? completedByName; // Name of the completer

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageBase64,
    this.location,
    required this.createdAt,
    this.completedBy,
    this.completedByName,
  });

  factory TaskItem.fromMap(String id, Map<String, dynamic> data) {
    return TaskItem(
      id: id,
      title: _safeString(data['title']) ?? '',
      description: _safeString(data['description']) ?? '',
      imageBase64: _safeString(data['imageBase64']),
      location: _safeString(data['location']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedBy: _safeString(data['completedBy']),
      completedByName: _safeString(data['completedByName']),
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
      'completedByName': completedByName,
    };
  }
}
