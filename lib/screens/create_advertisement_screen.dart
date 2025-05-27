import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/advertisement_model.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdvertisementScreen extends StatefulWidget {
  @override
  _CreateAdvertisementScreenState createState() => _CreateAdvertisementScreenState();
}

class _CreateAdvertisementScreenState extends State<CreateAdvertisementScreen> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _firebaseService = FirebaseService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  DocumentReference? currentUser;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (currentUserId != null) {
      currentUser = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitAd() async {
    if (_subjectController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    try {
      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await ImageService.uploadImage(_selectedImage!);
      }

      final ad = Advertisement(
        id: const Uuid().v4(),
        subject: _subjectController.text,
        description: _descController.text,
        imageUrl: imageUrl, // Use the uploaded image URL
        createdBy: currentUser ?? FirebaseFirestore.instance.collection('users').doc('unknown_user'),
        createdAt: Timestamp.now(),
        isApproved: false,
        reason: 'null',
      );

      await _firebaseService.addAdvertisement(ad);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Advertisement submitted for approval'))
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create advertisement: $e'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Advertisement')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            
            Text('Add Image (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 150,
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
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Select Image'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            
            Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitAd,
              child: _isLoading 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Submit Advertisement'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
