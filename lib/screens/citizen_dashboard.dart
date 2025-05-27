import 'package:flutter/material.dart';
import 'package:project/services/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../models/advertisement_model.dart';
import '../models/poll_model.dart';
import '../providers/announcement_provider.dart';
import '../services/firebase_service.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'user_report_screen.dart';

class CitizenDashboard extends StatefulWidget {
  @override
  _CitizenDashboardState createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  late Future<void> _future;
  final FirebaseService _firebaseService = FirebaseService();
  int _currentIndex = 0;
  final Map<String, bool> _userVotes = {}; // Track votes in memory

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() {
    return Provider.of<AnnouncementProvider>(context, listen: false).fetchAnnouncements();
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    NavigationService.navigateTo('/');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Citizen Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _future = _loadData();
              });
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
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
      body: _buildBody(provider),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AnnouncementProvider provider) {
    if (_currentIndex == 1) return MessagesScreen();
    if (_currentIndex == 2) return EmergencyContactsScreen();
    if (_currentIndex == 3) return ProfileScreen();
    if (_currentIndex == 4) return UserReportsScreen();

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final announcements = provider.announcements;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.blue,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Announcements', Icons.announcement),
                if (announcements.isEmpty)
                  _buildEmptyState('No announcements available', Icons.announcement),
                ...announcements.map(_buildAnnouncementCard),

                _buildSectionTitle('Active Polls', Icons.poll),
                _buildPollsSection(),

                _buildSectionTitle('Advertisements', Icons.campaign),
                _buildAdvertisementsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollsSection() {
    return StreamBuilder<List<Poll>>(
      stream: _firebaseService.getPollsStream().map((polls) => 
          polls.where((poll) => poll.isActive).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildEmptyState('Error loading polls', Icons.error_outline);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No active polls available', Icons.poll);
        }

        final polls = snapshot.data!;
        return Column(
          children: polls.map(_buildPollCard).toList(),
        );
      },
    );
  }

  Widget _buildAdvertisementsSection() {
    return StreamBuilder<List<Advertisement>>(
      stream: _firebaseService.getApprovedAdvertisementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildEmptyState('Error loading ads', Icons.error_outline);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No approved ads available', Icons.campaign);
        }

        final ads = snapshot.data!;
        return Column(
          children: ads.map(_buildAdCard).toList(),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement ann) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationService.navigateTo('/announcement_detail', arguments: {'announcement': ann});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ann.subject,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                ann.announcement.length > 100
                    ? '${ann.announcement.substring(0, 100)}...'
                    : ann.announcement,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Read more',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollCard(Poll poll) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final totalVotes = poll.yesVotes + poll.noVotes;
    final yesPercentage = totalVotes > 0 ? (poll.yesVotes / totalVotes * 100).round() : 0;
    final noPercentage = totalVotes > 0 ? (poll.noVotes / totalVotes * 100).round() : 0;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final hasVoted = _userVotes.containsKey(poll.id) || 
                    (currentUser != null && poll.votedUserIds.contains(currentUser.uid));

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationService.navigateTo('/poll_detail', arguments: {'poll': poll});
        },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    poll.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: poll.isActive 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    poll.isActive ? 'ACTIVE' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: poll.isActive ? Colors.green.shade800 : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              poll.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Ends: ${dateFormat.format(poll.endDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Spacer(),
                Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '$totalVotes votes',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (poll.isActive && !hasVoted) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _voteOnPoll(poll.id, true),
                      child: Text('Yes'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _voteOnPoll(poll.id, false),
                      child: Text('No'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (hasVoted || !poll.isActive) ...[
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: totalVotes > 0 ? poll.yesVotes / totalVotes : 0,
                backgroundColor: Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Yes: '),
                        TextSpan(
                          text: '$yesPercentage%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' (${poll.yesVotes})'),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'No: '),
                        TextSpan(
                          text: '$noPercentage%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' (${poll.noVotes})'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAdCard(Advertisement ad) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationService.navigateTo('/advertisement_detail', arguments: {'advertisement': ad});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                ad.subject,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                ad.description.length > 100
                    ? '${ad.description.substring(0, 100)}...'
                    : ad.description,
                style: TextStyle(fontSize: 16),
              ),
              if (ad.imageUrl != null) ...[
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey.shade100,
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
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _voteOnPoll(String pollId, bool isYesVote) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (_userVotes.containsKey(pollId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already voted on this poll')),
        );
        return;
      }

      final result = await _firebaseService.voteOnPoll(
        pollId: pollId,
        userId: currentUser.uid,
        isYesVote: isYesVote,
      );

      if (result) {
        setState(() {
          _userVotes[pollId] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your ${isYesVote ? 'yes' : 'no'} vote was recorded')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record your vote')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: $e')),
      );
    }
  }
}