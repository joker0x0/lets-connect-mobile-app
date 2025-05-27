import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../widgets/comment_section.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;
  final bool allowCommenting;

  AnnouncementDetailScreen({
    required this.announcement,
    this.allowCommenting = true,
  });

  @override
  Widget build(BuildContext context) {
    // Safe date formatting with null check
    String formattedDate;
    try {
      final dateFormat = DateFormat('MMM dd, yyyy');
      formattedDate = announcement.date != 'null'
          ? dateFormat.format(announcement.date) 
          : 'Date not available';
    } catch (e) {
      formattedDate = 'Date not available';
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section if available
              if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: 300),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      announcement.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              SizedBox(height: 16),
              Text(
                announcement.subject,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Posted on $formattedDate', style: TextStyle(color: Colors.grey)),
              Divider(height: 32),
              Text(
                announcement.announcement,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              if (allowCommenting) ...[
                Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                CommentSection(
                  parentType: 'announcement',
                  parentId: announcement.id,
                  currentUserId: currentUser?.uid,
                  allowAnonymous: true, // Enable anonymous commenting
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
