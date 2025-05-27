import 'package:flutter/material.dart';
import '../models/advertisement_model.dart';
import 'package:intl/intl.dart';

class AdvertisementDetailScreen extends StatelessWidget {
  final Advertisement advertisement;

  const AdvertisementDetailScreen({Key? key, required this.advertisement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Advertisement Details'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge for sponsored content
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'SPONSORED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Title
            Text(
              advertisement.subject,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Posted: ${dateFormat.format(advertisement.createdAt.toDate())}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Image if available
            if (advertisement.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  advertisement.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
            ],
            
            // Description
            Text(
              advertisement.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}