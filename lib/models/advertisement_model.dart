import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String id;
  final String subject;
  final String description;
  final String? imageUrl; // Change from imagePath to imageUrl
  final DocumentReference createdBy;
  final Timestamp createdAt;
  final bool isApproved;
  final String reason;

  Advertisement({
    required this.id,
    required this.subject,
    required this.description,
    this.imageUrl, // Now accepts imageUrl instead of imagePath
    required this.createdBy,
    required this.createdAt,
    required this.isApproved,
    required this.reason,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json, {String? id}) {
    return Advertisement(
      id: id ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'], // This will be null if imageUrl doesn't exist
      createdBy: json['createdBy'] is DocumentReference 
          ? json['createdBy'] as DocumentReference
          : FirebaseFirestore.instance.doc('users/unknown'),
      createdAt: json['createdAt'] is Timestamp 
          ? json['createdAt'] as Timestamp 
          : Timestamp.now(),
      isApproved: json['isApproved'] ?? false,
      reason: json['reason'] ?? 'null',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl, // Only include if not null
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isApproved': isApproved,
      'reason': reason,
    };
  }
}
