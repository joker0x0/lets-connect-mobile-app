// emergency_contacts_screen.dart
import 'package:flutter/material.dart';
import 'citizen_dashboard.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => CitizenDashboard(),
              ), (Route<dynamic> route) => false,);
          },
        ),
        title: Text('Emergency Contacts'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.getOfficialPhoneNumbersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading contacts'));
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(child: Text('No emergency contacts available'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactCard(context, contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Map<String, dynamic> contact) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(Icons.phone, color: Colors.red),
        title: Text(
          contact['description'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          contact['number'],
          style: TextStyle(fontSize: 14),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone),
          color: Colors.green,
          onPressed: () async {
            final Uri phoneUri = Uri(scheme: 'tel', path: contact['number']);
            try {
              await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
            } catch (e) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open dialer app')),
              );
            }
          },
        ),
      ),
    );
  }
}