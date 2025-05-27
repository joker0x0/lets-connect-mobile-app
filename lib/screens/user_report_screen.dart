import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:project/models/report_model.dart';
import 'package:project/services/firebase_service.dart';
import 'package:project/services/navigation_service.dart';
class UserReportsScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();
  
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Center(child: Text('No authenticated user'));
    }
    
    return Scaffold(
      appBar: AppBar(        
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => NavigationService.navigateTo('/citizen'),
        ),
        title: Text('My Reports'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<List<Report>>(
        stream: _firebaseService.getUserReportsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reports'));
          }
          
          final reports = snapshot.data ?? [];
          
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No reports submitted yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, report);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/report_problem');
        },
        backgroundColor: Colors.blue.shade800,
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildReportCard(BuildContext context, Report report) {
    // Status color mapping
    final statusColors = {
      'pending': Colors.orange,
      'in-progress': Colors.blue,
      'resolved': Colors.green,
    };
    
    // Convert GeoPoint to LatLng for flutter_map
    final LatLng reportLocation = LatLng(
      report.location.latitude,
      report.location.longitude,
    );
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report images in a horizontal scroll
          if (report.imageUrls.isNotEmpty)
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(report.imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColors[report.status.toLowerCase()]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColors[report.status.toLowerCase()],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Report title
                Text(
                  report.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Report description
                Text(report.description),
                SizedBox(height: 8),
                
                // Report location map
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: reportLocation,
                        initialZoom: 15,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.none,  // Disable interactions for preview
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: reportLocation,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Report date
                Text(
                  'Reported on ${DateFormat('MMM dd, yyyy').format(report.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                // Admin response section
                if (report.adminResponse != null && report.adminResponse!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response from Administration:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(report.adminResponse!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}