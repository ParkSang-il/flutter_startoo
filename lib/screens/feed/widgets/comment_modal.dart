import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/comment_model.dart';
import '../../../utils/snackbar_helper.dart';

class CommentModal extends StatefulWidget {
  final int portfolioId;

  const CommentModal({super.key, required this.portfolioId});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int? _replyingToCommentId;
  String? _replyingToUsername;
  final Map<int, List<Comment>> _repliesMap = {};
  final Map<int, bool> _repliesExpandedMap = {};
  final Map<int, bool> _repliesLoadingMap = {};

  // 입력 필드 텍스트 여부 감지용
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
    _commentController.addListener(() {
      setState(() {
        _isTextEmpty = _commentController.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      if (!_isLoadingMore && _currentPage < _lastPage) {
        _loadMoreComments();
      }
    }
  }

  Future<void> _loadComments({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _comments = [];
      });
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getComments(widget.portfolioId, perPage: 15);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        if (response.success && response.data != null) {
          if (reset) {
            _comments = response.data!.comments;
          } else {
            _comments.addAll(response.data!.comments);
          }
          _currentPage = response.data!.pagination.currentPage;
          _lastPage = response.data!.pagination.lastPage;
        } else {
          SnackBarHelper.showError(context, response.message);
        }
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getComments(widget.portfolioId, perPage: 15);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;

        if (response.success && response.data != null) {
          _comments.addAll(response.data!.comments);
          _currentPage = response.data!.pagination.currentPage;
          _lastPage = response.data!.pagination.lastPage;
        }
      });
    }
  }

  Future<void> _loadReplies(int commentId) async {
    if (_repliesLoadingMap[commentId] == true) return;

    setState(() {
      _repliesLoadingMap[commentId] = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getReplies(widget.portfolioId, commentId);

    if (mounted) {
      setState(() {
        _repliesLoadingMap[commentId] = false;

        if (response.success && response.data != null) {
          _repliesMap[commentId] = response.data!.replies;
          _repliesExpandedMap[commentId] = true;
        } else {
          SnackBarHelper.showError(context, response.message);
        }
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.createComment(
      widget.portfolioId,
      content,
      parentId: _replyingToCommentId,
    );

    if (mounted) {
      if (response.success && response.data != null) {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
        });
        
        // 댓글 목록 새로고침
        await _loadComments(reset: true);
      } else {
        SnackBarHelper.showError(context, response.message);
      }
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = comment.user.username;
    });
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _commentController.clear();
  }

  void _toggleReplies(int commentId) {
    if (_repliesExpandedMap[commentId] == true) {
      setState(() {
        _repliesExpandedMap[commentId] = false;
      });
    } else {
      if (_repliesMap[commentId] == null) {
        _loadReplies(commentId);
      } else {
        setState(() {
          _repliesExpandedMap[commentId] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212), // 다크 테마 배경색
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 1. 상단 그랩 바 & 헤더
              _buildHeader(),

              // 2. 댓글 목록
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _comments.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    return _buildCommentItem(_comments[index]);
                  },
                ),
              ),

              // 3. 댓글 입력 영역 (키보드 위로 고정)
              _buildInputArea(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade900),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade700),
        const SizedBox(height: 16),
        const Text(
          '첫 번째 댓글을 남겨보세요!',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final replies = _repliesMap[comment.id];
    final isExpanded = _repliesExpandedMap[comment.id] == true;
    final isLoading = _repliesLoadingMap[comment.id] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(comment.user.profileImage, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.user.username,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.timeAgo,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        if (comment.isPinned) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.push_pin, size: 12, color: Colors.blueAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _startReply(comment),
                      child: Text(
                        '답글 달기',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 대댓글 섹션
          if (comment.repliesCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _toggleReplies(comment.id),
                    child: Row(
                      children: [
                        Container(width: 20, height: 1, color: Colors.grey.shade800),
                        const SizedBox(width: 8),
                        Text(
                          isExpanded ? '답글 숨기기' : '답글 ${comment.repliesCount}개 더 보기',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
                          ),
                      ],
                    ),
                  ),
                  if (isExpanded && replies != null)
                    ...replies.map((reply) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildReplyItem(reply),
                    )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Comment reply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(reply.user.profileImage, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.user.username,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reply.timeAgo,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reply.content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String url, {double radius = 16}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Icon(Icons.person, size: radius, color: Colors.grey.shade600)
          : null,
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.grey.shade900)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '@$_replyingToUsername 님에게 답글 남기는 중',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              _buildAvatar('', radius: 18), // 현재 사용자 아바타 (Provider에서 가져와야 함)
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '코멘트 남기기...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isTextEmpty ? null : _submitComment,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '게시',
                  style: TextStyle(
                    color: _isTextEmpty ? Colors.grey.shade700 : Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

