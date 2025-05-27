// poll_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poll_model.dart';
import '../services/firebase_service.dart';
import '../widgets/comment_section.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollDetailsScreen extends StatelessWidget {
  final Poll poll;
  
  const PollDetailsScreen({Key? key, required this.poll}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasVoted = currentUser != null && poll.votedUserIds.contains(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Poll Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPollCard(context, poll, hasVoted),
            SizedBox(height: 20),
            CommentSection(
              parentType: 'poll',
              parentId: poll.id,
              currentUserId: currentUser?.uid,
              allowAnonymous: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollCard(BuildContext context, Poll poll, bool hasVoted) {
    final totalVotes = poll.yesVotes + poll.noVotes;
    final yesPercentage = totalVotes > 0 ? (poll.yesVotes / totalVotes * 100).round() : 0;
    final noPercentage = totalVotes > 0 ? (poll.noVotes / totalVotes * 100).round() : 0;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      fontSize: 20,
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
                      onPressed: () => _voteOnPoll(context, poll.id, true),
                      child: Text('Yes'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _voteOnPoll(context, poll.id, false),
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
          ],
        ),
      ),
    );
  }

  Future<void> _voteOnPoll(BuildContext context, String pollId, bool isYesVote) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final result = await FirebaseService().voteOnPoll(
        pollId: pollId,
        userId: currentUser.uid,
        isYesVote: isYesVote,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your ${isYesVote ? 'yes' : 'no'} vote was recorded')),
        );
        Navigator.pop(context); // Close the details screen
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