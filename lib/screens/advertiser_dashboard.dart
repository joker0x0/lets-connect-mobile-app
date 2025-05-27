import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/advertisement_model.dart';
import '../services/navigation_service.dart';
import '../widgets/advertisement_form.dart';

class AdvertiserDashboard extends StatefulWidget {
  @override
  _AdvertiserDashboardState createState() => _AdvertiserDashboardState();
}

class _AdvertiserDashboardState extends State<AdvertiserDashboard> {
  final FirebaseService service = FirebaseService();
  UniqueKey _refreshKey = UniqueKey(); // Key to trigger StreamBuilder rebuild

  void _refreshAdvertisements() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    NavigationService.navigateTo('/login');
  }

  Future<bool> _deleteAdvertisement(Advertisement ad) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Advertisement'),
      content: Text(
        'Are you sure you want to delete this advertisement? This action will also remove it from the citizen\'s dashboard.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      await service.deleteAdvertisement(ad.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Advertisement deleted successfully.')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete advertisement: $e')),
      );
    }
  }
  return false;
}


  Widget _buildStatusChip(Advertisement ad) {
    if (ad.isApproved) {
      return Chip(
        label: Text('Approved'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.check_circle, color: Colors.green.shade800, size: 18),
      );
    } else if (ad.reason.isNotEmpty && ad.reason != 'null') {
      return Chip(
        label: Text('Declined'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.cancel, color: Colors.red.shade800, size: 18),
      );
    } else {
      return Chip(
        label: Text('Pending'),
        backgroundColor: Colors.orange.shade100,
        labelStyle: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
        avatar: Icon(Icons.hourglass_empty, color: Colors.orange.shade800, size: 18),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Advertiser Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Ads',
            onPressed: _refreshAdvertisements,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Log Out'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: StreamBuilder<List<Advertisement>>(
          key: _refreshKey,
          stream: service.getAdvertisementsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading ads: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('No advertisements yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              );
            }

            final ads = snapshot.data!;
            return ListView.builder(
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index];
                return Dismissible(
                  key: Key(ad.id), // Assuming `id` is a unique identifier for each ad
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade100,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.red.shade800),
                  ),
                  confirmDismiss: (direction) => _deleteAdvertisement(ad),
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display image if available
                        if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              image: DecorationImage(
                                image: NetworkImage(ad.imageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.campaign, color: theme.primaryColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ad.subject,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(ad.description),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatusChip(ad),
                                  if (ad.reason.isNotEmpty && !ad.isApproved && ad.reason != 'null')
                                    Icon(Icons.info_outline, color: Colors.red.shade300),
                                ],
                              ),
                              if (ad.reason.isNotEmpty && !ad.isApproved && ad.reason != 'null') ...[
                                SizedBox(height: 8),
                                Text(
                                  'Reason: ${ad.reason}',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => AdvertisementForm(),
        ),
        icon: Icon(Icons.add),
        label: Text('New Ad'),
      ),
    );
  }
}
