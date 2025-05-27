// widgets/announcement_card.dart
import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    // Safe date formatting with try-catch
    String formattedDate;
    try {
      formattedDate = announcement.date != 'null'
          ? DateFormat.yMMMd().add_jm().format(announcement.date)
          : 'Date not available';
    } catch (e) {
      formattedDate = 'Date not available';
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(announcement.subject),
        subtitle: Text("Published on $formattedDate"),
        leading: Icon(Icons.announcement),
      ),
    );
  }
}
