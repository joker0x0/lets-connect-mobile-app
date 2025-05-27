import 'package:flutter/material.dart';
import 'package:project/screens/admin_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/widgets/phone_number_section.dart';
import '../services/navigation_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Bottom navigation bar items
  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message),
      label: 'Messages',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  // Screens for each tab
  final List<Widget> _screens = [
    // Dashboard Screen (index 0)
    _DashboardScreen(),
    // Messages Screen (index 1)
    AdminChatScreen(),
    // Settings Screen (index 2)
    _PlaceholderScreen(title: 'Settings'),
    // Analytics Screen (index 3)
    _PlaceholderScreen(title: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                NavigationService.navigateTo('/');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: _bottomNavItems,
      ),
    );
  }
}

// Dashboard Screen Widget
class _DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
      _DashboardCard(
        title: 'Announcements',
        icon: Icons.campaign,
        onTap: () => NavigationService.navigateTo('/admin/announcements'),
      ),
      _DashboardCard(
        title: 'Polls',
        icon: Icons.poll,
        onTap: () => NavigationService.navigateTo('/admin/polls'),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('advertisements')
          .where('isApproved', isEqualTo: false)
          .where('reason', isEqualTo: 'null')
          .snapshots(),
        builder: (context, snapshot) {
          final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return _DashboardCard(
            title: 'Advertisements ($pendingCount)',
            icon: Icons.ad_units,
            onTap: () => NavigationService.navigateTo('/admin/advertisements'),
          );
        },
      ),
      _DashboardCard(
        title: 'Users',
        icon: Icons.people,
        onTap: () {
        // Navigate to Users screen
        },
      ),
      _DashboardCard(
        title: 'Official Phone Numbers',
        icon: Icons.phone,
        expandableContent: OfficialPhoneNumbersSection(isAdmin: true),
      ),
      _DashboardCard(
        title: 'Citizen Reports',
        icon: Icons.report_problem,
        onTap: () => NavigationService.navigateTo('/admin/reports'),
      ),
      ],
    );
  }
}

// Placeholder Screen for under-development tabs
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This section is under development',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Dashboard Card Widget
class _DashboardCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget? expandableContent;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    this.expandableContent,
    this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _handleTap() {
    if (widget.expandableContent != null) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(widget.icon, size: 28, color: Colors.blue),
            title: Text(
              widget.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: widget.expandableContent != null
                ? Icon(_isExpanded ? Icons.expand_less : Icons.expand_more)
                : Icon(Icons.arrow_forward_ios, color: Colors.blue),
            onTap: _handleTap,
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: widget.expandableContent,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}