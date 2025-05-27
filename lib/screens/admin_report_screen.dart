import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:project/models/report_model.dart';
import 'package:project/services/firebase_service.dart';
import 'package:project/services/navigation_service.dart';

class AdminReportsScreen extends StatelessWidget {
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
        title: Text('Citizen Reports'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<List<Report>>(
        stream: _firebaseService.getAllReportsStream(),
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
      margin: EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report images in a horizontal scroll with indicator
          if (report.imageUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: report.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        report.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Gradient overlay for status badge
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColors[report.status.toLowerCase()] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          // User name
                          FutureBuilder<String>(
                            future: _firebaseService.getUserFullName(report.userId),
                            builder: (context, snapshot) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'By: ${snapshot.data ?? 'Unknown User'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report date with icon
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(report.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Report title
                Text(
                  report.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Report description with styling
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    report.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Location label
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue.shade800),
                    SizedBox(width: 4),
                    Text(
                      'Problem Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Report location map
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: reportLocation,
                        initialZoom: 15,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.none, // Disable interactions for preview
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
                
                // Admin response section
                if (report.adminResponse != null && report.adminResponse!.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 18, color: Colors.blue.shade800),
                            SizedBox(width: 8),
                            Text(
                              'Response from Administration',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          report.adminResponse!,
                          style: TextStyle(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 20),
                
                // Divider before action buttons
                Divider(color: Colors.grey.shade300),
                SizedBox(height: 12),

                // Action buttons in a more organized layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (report.status == 'pending')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateReportStatus(context, report.id, 'in-progress'),
                          icon: Icon(Icons.engineering, size: 18),
                          label: Text('Mark In Progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    if (report.status == 'pending' && report.status != 'resolved')
                      SizedBox(width: 8),
                    if (report.status != 'resolved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateReportStatus(context, report.id, 'resolved'),
                          icon: Icon(Icons.check_circle, size: 18),
                          label: Text('Mark Resolved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                
                // Response button as a full-width button
                ElevatedButton.icon(
                  onPressed: () => _showResponseDialog(context, report.id, report.adminResponse),
                  icon: Icon(Icons.reply),
                  label: Text('Add Response'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.blue.shade800,
                    minimumSize: Size(double.infinity, 42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateReportStatus(BuildContext context, String reportId, String status) async {
    try {
      await _firebaseService.updateReportStatus(reportId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update report: $e')),
      );
    }
  }
  
  void _showResponseDialog(BuildContext context, String reportId, String? currentResponse) {
    final responseController = TextEditingController(text: currentResponse);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Response to Report'),
        content: TextField(
          controller: responseController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter your response to this report',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firebaseService.updateReportStatus(
                  reportId, 
                  'in-progress', 
                  adminResponse: responseController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Response added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add response: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}