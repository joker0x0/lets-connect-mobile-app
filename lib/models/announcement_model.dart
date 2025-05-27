import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String subject;
  final String announcement;
  final DateTime date;
  final String? imageUrl; // Add optional image URL

  Announcement({
    required this.id,
    required this.subject,
    required this.announcement,
    required this.date,
    this.imageUrl, // Optional image URL
  });

  // From Firestore
  factory Announcement.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle various possible field names for date
    DateTime? dateTime;
    try {
      if (data['createdAt'] != null) {
        dateTime = (data['createdAt'] as Timestamp).toDate();
      } else if (data['date'] != null) {
        dateTime = (data['date'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    return Announcement(
      id: doc.id,
      subject: data['subject'] ?? '',
      announcement: data['announcement'] ?? '',
      date: dateTime ?? DateTime.now(), // Always provide a default date
      imageUrl: data['imageUrl'], // Get imageUrl if exists
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'announcement': announcement,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date), // Add both date fields for compatibility
      if (imageUrl != null) 'imageUrl': imageUrl, // Include imageUrl if not null
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json, String id) {
    // Handle various possible field names for date
    DateTime? dateTime;
    try {
      if (json['createdAt'] != null) {
        dateTime = (json['createdAt'] as Timestamp).toDate();
      } else if (json['date'] != null) {
        dateTime = (json['date'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing date in fromJson: $e');
    }

    return Announcement(
      id: id,
      subject: json['subject'] ?? '',
      announcement: json['announcement'] ?? '',
      date: dateTime ?? DateTime.now(), // Provide a fallback date if null
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'announcement': announcement,
      'createdAt': Timestamp.fromDate(date),
      'date': Timestamp.fromDate(date), // Add both date fields for compatibility
      if (imageUrl != null) 'imageUrl': imageUrl, // Include imageUrl if not null
    };
  }
}
