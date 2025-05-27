import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'announcement_detail_screen.dart';
import '../services/firebase_service.dart';
import '../models/announcement_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/image_service.dart';
class AdminAnnouncementsScreen extends StatefulWidget {
  @override
  _AdminAnnouncementsScreenState createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Replace the _uploadImage function with this
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Use ImageService instead of direct Firebase Storage access
      final imageUrl = await ImageService.uploadImage(_selectedImage!);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image'))
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Update your existing _uploadAnnouncement method to handle images
  Future<void> _uploadAnnouncement({String? docId}) async {
    if (_subjectController.text.isEmpty || _bodyController.text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to post an announcement')));
      return;
    }

    // Upload image if selected
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
    }

    if (imageUrl == null && _selectedImage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')));
      return;
    }
    
    final announcement = Announcement(
      id: docId ?? '',
      subject: _subjectController.text,
      announcement: _bodyController.text,
      date: DateTime.now(),
      imageUrl: imageUrl, // Add the image URL
    );

    if (docId != null) {
      await _firebaseService.updateAnnouncement(docId, announcement);
    } else {
      await _firebaseService.addAnnouncement(announcement);
    }

    // Clear the image state
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Announcement posted!')));
    _subjectController.clear();
    _bodyController.clear();
    Navigator.of(context).pop(); // close bottom sheet if open
  }

  // Update your existing _showEditForm to handle images
  void _showEditForm({Announcement? existing}) {
    if (existing != null) {
      _subjectController.text = existing.subject;
      _bodyController.text = existing.announcement;
      setState(() {
        _selectedImage = null;
        _uploadedImageUrl = existing.imageUrl;
      });
    } else {
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _selectedImage = null;
        _uploadedImageUrl = null;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'New Announcement' : 'Edit Announcement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Announcement'),
                maxLines: 6,
              ),
              SizedBox(height: 16),
              Text(
                'Attachment (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 14,
                        child: Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                      onPressed: () {
                        setModalState(() {
                          _selectedImage = null;
                          _uploadedImageUrl = null;
                        });
                      },
                    ),
                  ],
                )
              else if (_uploadedImageUrl != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_uploadedImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 14,
                        child: Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                      onPressed: () {
                        setModalState(() {
                          _uploadedImageUrl = null;
                        });
                      },
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    await _pickImage();
                    setModalState(() {}); // Refresh bottom sheet UI
                  },
                  icon: Icon(Icons.image),
                  label: Text('Add Image'),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  _isUploading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => _uploadAnnouncement(docId: existing?.id),
                          child: Text(existing == null ? 'Post' : 'Update'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _viewComments(Announcement announcement) {
      // Ensure the announcement has a valid date
    final safeAnnouncement = announcement.date != 'null' ? announcement : Announcement(
      id: announcement.id,
      subject: announcement.subject,
      announcement: announcement.announcement,
      date: DateTime.now(), // Provide a default date
      imageUrl: announcement.imageUrl,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(
          announcement: safeAnnouncement,
          allowCommenting: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 28),
            onPressed: () => _showEditForm(), // Use _showEditForm instead of _showAddAnnouncementDialog
            tooltip: 'Create new announcement',
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.announcement, size: 48, color: Colors.blue.shade300),
                    SizedBox(height: 16),
                    Text('No announcements yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tap the + button to create one',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (_, index) {
                final doc = docs[index];
                final announcement = Announcement.fromJson(
                    doc.data() as Map<String, dynamic>, doc.id);

                return Dismissible(
                  key: ValueKey(announcement.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Delete Announcement'),
                        content: Text('Are you sure you want to delete this announcement?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                        ],
                      ),
                    );
                    
                    if (shouldDelete == true) {
                      await _firebaseService.deleteAnnouncement(announcement.id); 
                      return true;
                    }
                    return false;
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _viewComments(announcement),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    announcement.subject,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditForm(existing: announcement), // Use _showEditForm instead of _showEditAnnouncementDialog
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              announcement.announcement,
                              style: TextStyle(fontSize: 16),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatDate(announcement.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not available';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
