import 'package:flutter/material.dart';
import 'package:project/models/poll_model.dart';
import 'package:project/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/comment_section.dart';

class AdminPollsScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Polls', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 28),
            tooltip: 'Create new poll',
            onPressed: () => _showAddPollDialog(context),
          ),
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
        child: StreamBuilder<List<Poll>>(
          stream: _firebaseService.getPollsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Failed to load polls',
                        style: TextStyle(fontSize: 18, color: Colors.red)),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                ),
              );
            }

            final polls = snapshot.data ?? [];

            if (polls.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.poll, size: 64, color: Colors.blue.shade300),
                    SizedBox(height: 16),
                    Text(
                      'No polls yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to create your first poll',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: polls.length,
              itemBuilder: (context, index) {
                final poll = polls[index];
                return _buildPollCard(context, poll);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPollDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
      ),
    );
  }

  Widget _buildPollCard(BuildContext context, Poll poll) {
  final dateFormat = DateFormat('MMM dd, yyyy');
  final totalVotes = poll.yesVotes + poll.noVotes;
  final yesPercentage = totalVotes > 0 ? (poll.yesVotes / totalVotes * 100).round() : 0;
  final noPercentage = totalVotes > 0 ? (poll.noVotes / totalVotes * 100).round() : 0;

  return Dismissible(
    key: Key(poll.id),
    direction: DismissDirection.endToStart,
    background: Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      child: Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      return await _showDeleteConfirmationDialog(context, poll.id);
    },
    child: Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPollDetails(context, poll),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      poll.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
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
              
              // Description
              Text(
                poll.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 16),
              
              // Date and Votes Row
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Ends: ${dateFormat.format(poll.endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Vote Progress Bar
              LinearProgressIndicator(
                value: totalVotes > 0 ? poll.yesVotes / totalVotes : 0,
                backgroundColor: Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              
              SizedBox(height: 8),
              
              // Vote Percentages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Yes: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        TextSpan(
                          text: '$yesPercentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        TextSpan(
                          text: ' (${poll.yesVotes})',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'No: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        TextSpan(
                          text: '$noPercentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        TextSpan(
                          text: ' (${poll.noVotes})',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 12),
              
              // Action Buttons (without delete button)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.comment,
                      color: Colors.purple,
                      label: 'Comments',
                      onPressed: () => _showCommentsDialog(context, poll.id),
                    ),
                    if (poll.isActive) ...[
                      SizedBox(width: 8),
                      _buildActionButton(
                        context,
                        icon: Icons.edit,
                        color: Colors.blue,
                        label: 'Edit',
                        onPressed: () => _showEditPollDialog(context, poll),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        context,
                        icon: Icons.close,
                        color: Colors.orange,
                        label: 'Close',
                        onPressed: () => _firebaseService.closePoll(poll.id),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context, String pollId) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Poll'),
      content: Text('Are you sure you want to delete this poll? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _firebaseService.deletePoll(pollId);
            Navigator.of(context).pop(true);
          },
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;
}

// In admin_polls_screen.dart
  void _showCommentsDialog(BuildContext context, String pollId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Poll Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: CommentSection(
                  parentType: 'poll',
                  parentId: pollId,
                  currentUserId: null, // Prevents admin from commenting
                  allowAnonymous: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }

  void _showPollDetails(BuildContext context, Poll poll) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(poll.title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(poll.description),
              SizedBox(height: 16),
              Text(
                'End Date: ${DateFormat('MMM dd, yyyy').format(poll.endDate)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              if (poll.isActive)
                Text(
                  'This poll is currently active',
                  style: TextStyle(color: Colors.green.shade600),
                )
              else
                Text(
                  'This poll is closed',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  void _showAddPollDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime endDate = DateTime.now().add(Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New Poll'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Poll Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('End Date:'),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (selectedDate != null) {
                              setState(() => endDate = selectedDate);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && 
                        descriptionController.text.isNotEmpty) {
                      final poll = Poll(
                        id: '',
                        title: titleController.text,
                        description: descriptionController.text,
                        createdAt: DateTime.now(),
                        endDate: endDate,
                      );
                      _firebaseService.createPoll(poll);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPollDialog(BuildContext context, Poll poll) {
    final titleController = TextEditingController(text: poll.title);
    final descriptionController = TextEditingController(text: poll.description);
    DateTime endDate = poll.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Poll'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Poll Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('End Date:'),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (selectedDate != null) {
                              setState(() => endDate = selectedDate);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && 
                        descriptionController.text.isNotEmpty) {
                      final updatedPoll = Poll(
                        id: poll.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        createdAt: poll.createdAt,
                        endDate: endDate,
                        isActive: poll.isActive,
                      );
                      _firebaseService.updatePoll(poll.id, updatedPoll);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}