import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? createdBy;
  final bool isAnonymous;
  final String parentType;
  final String parentId;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.createdBy,
    required this.isAnonymous,
    required this.parentType,
    required this.parentId,
  });

  factory Comment.fromMap(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      content: data['content'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      isAnonymous: data['isAnonymous'],
      parentType: data['parentType'],
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isAnonymous': isAnonymous,
      'parentType': parentType,
      'parentId': parentId,
    };
  }
}
