import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final GeoPoint location;
  final String status; // 'pending', 'in-progress', 'resolved'
  final String? adminResponse;
  
  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.imageUrls,
    required this.location,
    required this.status,
    this.adminResponse,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'imageUrls': imageUrls,
      'location': location,
      'status': status,
      'adminResponse': adminResponse,
    };
  }
  
  static Report fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
      status: data['status'] ?? 'pending',
      adminResponse: data['adminResponse'],
    );
  }
}