import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementProvider with ChangeNotifier {
  List<Announcement> _announcements = [];

  List<Announcement> get announcements => _announcements;

  Future<void> fetchAnnouncements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .get();

    _announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc)).toList();
    notifyListeners();
  }
}
