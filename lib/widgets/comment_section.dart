import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/comment_model.dart';
import '../services/firebase_service.dart';

class CommentSection extends StatefulWidget {
  final String parentType;
  final String parentId;
  final String? currentUserId;
  final bool allowAnonymous;

  const CommentSection({
    required this.parentType,
    required this.parentId,
    required this.currentUserId,
    this.allowAnonymous = false,
    Key? key,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentsList(),
        const Divider(height: 24),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<List<Comment>>(
      stream: FirebaseService().fetchComments(widget.parentType, widget.parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load comments');
        }

        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return _buildEmptyState('No comments yet');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (_, index) => _buildCommentItem(comments[index]),
        );
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return FutureBuilder<String>(
      future: comment.isAnonymous
          ? Future.value('Anonymous')
          : FirebaseService().getUserFullName(comment.createdBy ?? ''),
      builder: (context, userSnapshot) {
        final displayName = userSnapshot.data ?? 'Loading...';
        final isOwnComment = comment.createdBy == widget.currentUserId;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOwnComment 
                ? Colors.blue.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(comment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Column(
      children: [
        if (widget.allowAnonymous)
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) => setState(() => _isAnonymous = value ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('Post anonymously'),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            _isSubmitting
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _submitComment,
                  ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = Comment(
        id: '',
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: _isAnonymous ? null : widget.currentUserId,
        isAnonymous: _isAnonymous,
        parentType: widget.parentType,
        parentId: widget.parentId,
      );

      await FirebaseService().addComment(comment);
      _commentController.clear();
      setState(() => _isAnonymous = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}