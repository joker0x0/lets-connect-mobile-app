import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement_model.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';

class AdvertisementForm extends StatefulWidget {
  @override
  _AdvertisementFormState createState() => _AdvertisementFormState();
}

class _AdvertisementFormState extends State<AdvertisementForm> {
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

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
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

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to create an advertisement'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ImageService.uploadImage(_selectedImage!);
      }

      final ad = Advertisement(
        id: '', // Will be assigned by Firestore
        subject: _subjectController.text,
        description: _descController.text,
        imageUrl: imageUrl, // Store the image URL
        createdBy: currentUser!,
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create New Advertisement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.subject),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 20),
          
          // Image selection section
          Text(
            'Add Image (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          
          SizedBox(height: 24),
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
          SizedBox(height: 8),
          Text(
            'Note: Your advertisement will be reviewed by the admin before publishing.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
