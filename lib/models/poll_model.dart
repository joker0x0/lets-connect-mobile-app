import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime endDate;
  final int yesVotes;
  final int noVotes;
  final List<String> votedUserIds; // Track who voted (for prevention only)
  final bool isActive;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.endDate,
    this.yesVotes = 0,
    this.noVotes = 0,
    List<String>? votedUserIds,
    this.isActive = true,
  }) : votedUserIds = votedUserIds ?? [];

  factory Poll.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      yesVotes: data['yesVotes'] ?? 0,
      noVotes: data['noVotes'] ?? 0,
      votedUserIds: List<String>.from(data['votedUserIds'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': Timestamp.fromDate(endDate),
      'yesVotes': yesVotes,
      'noVotes': noVotes,
      'votedUserIds': votedUserIds,
      'isActive': isActive,
    };
  }
}