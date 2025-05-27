import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'citizen_dashboard.dart';
import 'package:project/services/firebase_service.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final userId = _auth.currentUser!.uid;
    await _firebaseService.getCitizenChatDoc(userId).set({
      'participants': ['government', userId],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => CitizenDashboard()),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Government Support'),
            StreamBuilder<DocumentSnapshot>(
              stream: _firebaseService.getCitizenChatDoc(userId).snapshots(),
              builder: (context, snapshot) {
                final status = snapshot.hasData && 
                    (snapshot.data!.data() as Map<String, dynamic>?)?['status'] == 'online'
                    ? 'Online'
                    : 'Offline';
                return Text(
                  status,
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getMessagesStream(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isGovernment = data['sender'] == 'government';
                    
                    return _buildMessageBubble(
                      text: data['text'],
                      isGovernment: isGovernment,
                      time: _firebaseService.formatMessageTimestamp(
                        data['timestamp'] as Timestamp),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(userId),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isGovernment,
    required String time,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isGovernment ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isGovernment ? Colors.grey.shade200 : Colors.blue.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyle(
                color: isGovernment ? Colors.black : Colors.white,
              )),
              SizedBox(height: 4),
              Text(time, style: TextStyle(
                fontSize: 10,
                color: isGovernment ? Colors.grey.shade600 : Colors.white70,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(String userId) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () async {
                if (_messageController.text.isNotEmpty) {
                  try {
                    await _firebaseService.sendMessage(
                      userId,
                      _messageController.text,
                      false, // isGovernment flag
                    );
                    _messageController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send message: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}