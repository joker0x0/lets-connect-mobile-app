import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/services/firebase_service.dart';
import '../services/navigation_service.dart';

class AdminChatScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            NavigationService.replaceTo('/admin');
          },
        ),
        title: Text('Citizen Messages', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final userId = chatDoc['participants'][1]; // Get citizen ID
              
              return FutureBuilder(
                future: _firebaseService.getUserFullName(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(userSnapshot.data ?? 'Unknown User'),
                    subtitle: Text(
                      chatDoc['lastMessage'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _firebaseService.formatMessageTimestamp(
                        chatDoc['lastMessageTime'] as Timestamp),
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      NavigationService.navigateTo('/admin/chat/detail', arguments: {
                        'userId': userId,
                        'userName': userSnapshot.data ?? 'User',
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

