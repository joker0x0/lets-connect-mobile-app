import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/services/firebase_service.dart';
import 'package:project/models/advertisement_model.dart';

class AdminAdvertisementsScreen extends StatefulWidget {
  const AdminAdvertisementsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAdvertisementsScreen> createState() => _AdminAdvertisementsScreenState();
}

class _AdminAdvertisementsScreenState extends State<AdminAdvertisementsScreen> {
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  // Sort ads by status: Pending → Approved → Declined
  List<QueryDocumentSnapshot> _sortAds(List<QueryDocumentSnapshot> ads) {
    return ads..sort((a, b) {
      final aApproved = a['isApproved'] ?? false;
      final bApproved = b['isApproved'] ?? false;
      final aReason = a['reason'] ?? 'null';
      final bReason = b['reason'] ?? 'null';

      // Pending comes first
      if (!aApproved && aReason == 'null' && (bApproved || bReason != 'null')) return -1;
      if (!bApproved && bReason == 'null' && (aApproved || aReason != 'null')) return 1;

      // Approved comes next
      if (aApproved && !bApproved) return -1;
      if (bApproved && !aApproved) return 1;

      // Then sort by creation date (newest first)
      final aDate = (a['createdAt'] as Timestamp).toDate();
      final bDate = (b['createdAt'] as Timestamp).toDate();
      return bDate.compareTo(aDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement Approvals'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
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
          key: _refreshKey,
          stream: FirebaseFirestore.instance.collection('advertisements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error loading advertisements', 
                        style: TextStyle(fontSize: 18, color: Colors.red)),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            final ads = _sortAds(snapshot.data!.docs);

            if (ads.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ad_units_outlined, size: 48, color: Colors.blue.shade300),
                    SizedBox(height: 16),
                    Text('No advertisements found',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: ads.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ad = ads[index];
                final subject = ad['subject'] ?? 'No Subject';
                final createdAt = (ad['createdAt'] as Timestamp).toDate();
                final isApproved = ad['isApproved'] ?? false;
                final reason = ad['reason'] ?? '';
                final userId = (ad['createdBy'] as DocumentReference).id;
                String? imageUrl;
                try {
                  // Check if the field exists before trying to access it
                  if (ad.data() is Map && (ad.data() as Map).containsKey('imageUrl')) {
                    imageUrl = ad['imageUrl'];
                  }
                } catch (e) {
                  imageUrl = null; // Handle any errors
                }

                return FutureBuilder<String>(
                  future: FirebaseService().getUserFullName(userId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildAdCard(
                        context: context,
                        subject: subject,
                        createdAt: createdAt,
                        status: 'Loading...',
                        statusColor: Colors.grey,
                        username: 'Loading...',
                        isPending: false,
                        reason: reason,
                        imageUrl: imageUrl, // Pass imageUrl
                        onApprove: null,
                        onDecline: null,
                      );
                    }

                    final username = userSnapshot.data ?? 'Unknown User';
                    final isPending = !isApproved && reason == 'null';

                    return _buildAdCard(
                      context: context,
                      subject: subject,
                      createdAt: createdAt,
                      status: isApproved ? 'Approved' : isPending ? 'Pending' : 'Declined',
                      statusColor: isApproved 
                          ? Colors.green 
                          : isPending 
                              ? Colors.orange 
                              : Colors.red,
                      username: username,
                      isPending: isPending,
                      reason: reason,
                      imageUrl: imageUrl, // Use the safely retrieved imageUrl
                      onApprove: isPending ? () async {
                        try {
                          final updatedAd = {
                            ...ad.data() as Map<String, dynamic>,
                            'isApproved': true,
                          };
                          await FirebaseService().updateAdvertisement(
                            ad.id,
                            Advertisement.fromJson(updatedAd),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to approve ad: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      onDecline: isPending ? () {
                        _showDeclineDialog(context, ad);
                      } : null,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showDeclineDialog(BuildContext context, QueryDocumentSnapshot ad) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Advertisement', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for declining this ad:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter decline reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final declineReason = reasonController.text.trim();
              if (declineReason.isNotEmpty) {
                try {
                  final updatedAd = {
                    ...ad.data() as Map<String, dynamic>,
                    'isApproved': false,
                    'reason': declineReason,
                  };
                  await FirebaseService().updateAdvertisement(
                    ad.id,
                    Advertisement.fromJson(updatedAd),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to decline ad: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('SUBMIT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard({
    required BuildContext context,
    required String subject,
    required DateTime createdAt,
    required String status,
    required Color statusColor,
    required String username,
    required bool isPending,
    required String reason,
    String? imageUrl, // Add imageUrl parameter
    VoidCallback? onApprove,
    VoidCallback? onDecline,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display image if available
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.person, username),
                _buildInfoRow(Icons.calendar_today, 
                    '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'),
                if (!isPending && reason.isNotEmpty && reason != 'null')
                  _buildInfoRow(Icons.info, 'Decline Reason: $reason', color: Colors.red),
                if (isPending)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.close, color: Colors.red),
                          label: Text('Decline', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onDecline,
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text('Approve', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color ?? Colors.grey.shade700)),
        ],
      ),
    );
  }
}