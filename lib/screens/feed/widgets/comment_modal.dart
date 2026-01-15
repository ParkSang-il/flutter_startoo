import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/comment_model.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/custom_snackbar.dart';

class CommentModal extends StatefulWidget {
  final int portfolioId;
  final int portfolioOwnerId; // 포트폴리오 작성자 ID
  final BuildContext? parentContext; // 모달을 연 원본 context

  const CommentModal({
    super.key,
    required this.portfolioId,
    required this.portfolioOwnerId,
    this.parentContext,
  });

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
  
  // 댓글 작성 여부 추적 (피드 리스트 새로고침용)
  bool _commentAdded = false;
  
  // 모달 내부 알림 표시용 (하단, 최상위 레이어)
  String? _snackBarMessage;
  bool _snackBarIsError = false;
  
  // 댓글 수정 관련
  int? _editingCommentId;

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
  
  // SnackBar 표시 헬퍼 (모달 내부 하단, 최상위 레이어)
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _snackBarMessage = message;
        _snackBarIsError = isError;
      });
      
      // 2초 후 자동으로 사라지게
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _snackBarMessage = null;
          });
        }
      });
    }
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
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _isLoading = true;
          _isLoadingMore = false;
          _comments = [];
          // 대댓글 맵도 초기화
          _repliesMap.clear();
          _repliesExpandedMap.clear();
          _repliesLoadingMap.clear();
        });
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getComments(widget.portfolioId, perPage: 15);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        if (response.success && response.data != null) {
          // API에서 순서대로 보내주므로 정렬하지 않음
          if (reset) {
            _comments = response.data!.comments;
          } else {
            _comments.addAll(response.data!.comments);
          }
          _currentPage = response.data!.pagination.currentPage;
          _lastPage = response.data!.pagination.lastPage;
        } else {
          if (response.message.isNotEmpty) {
            _showSnackBar(context, response.message, isError: true);
          }
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

    // 키보드 닫기
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 수정 모드인 경우
    if (_editingCommentId != null) {
      // 현재 댓글 목록에서 수정하려는 댓글 찾기
      Comment? editingComment;
      for (var comment in _comments) {
        if (comment.id == _editingCommentId) {
          editingComment = comment;
          break;
        }
        // 대댓글도 확인
        if (_repliesMap[comment.id] != null) {
          for (var reply in _repliesMap[comment.id]!) {
            if (reply.id == _editingCommentId) {
              editingComment = reply;
              break;
            }
          }
        }
      }
      
      // 대댓글이 있는 경우 수정 불가
      if (editingComment != null && editingComment.repliesCount > 0) {
        _showSnackBar(context, '대댓글이 있는 댓글은 수정할 수 없습니다.', isError: true);
        _cancelEditComment();
        return;
      }
      
      final response = await authProvider.updateComment(
        widget.portfolioId,
        _editingCommentId!,
        content,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          _commentController.clear();
          setState(() {
            _editingCommentId = null;
            _replyingToCommentId = null;
            _replyingToUsername = null;
            _commentAdded = true; // 댓글 수정 완료 표시
          });
          
          // 댓글 목록 새로고침 - API를 다시 호출하여 최신 데이터 가져오기
          await _loadComments(reset: true);
          _showSnackBar(context, '댓글이 수정되었습니다.', isError: false);
        } else {
          _showSnackBar(context, response.message, isError: true);
        }
      }
    } else {
      // 댓글 작성 모드
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
            _commentAdded = true; // 댓글 작성 완료 표시
          });
          
          // 댓글 목록 새로고침 - API를 다시 호출하여 최신 데이터 가져오기
          await _loadComments(reset: true);
          
          // 댓글 작성 성공 시 모달이 닫힐 때 피드 리스트 새로고침을 위해 결과 반환
          // 모달을 닫을 때 true를 반환하여 피드 리스트를 새로고침하도록 함
        } else {
          SnackBarHelper.showError(context, response.message);
        }
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
      _editingCommentId = null;
    });
    _commentController.clear();
  }

  // 댓글 고정/해제
  Future<void> _pinComment(int commentId, bool isPinned) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.pinComment(
      widget.portfolioId,
      commentId,
      isPinned,
    );

    if (mounted) {
      if (response.success) {
        // 댓글 목록 새로고침 - 명시적으로 리셋하고 로딩
        setState(() {
          _currentPage = 1;
          _isLoading = true;
          _isLoadingMore = false;
          _comments = [];
        });
        
        // API 호출하여 댓글 목록 다시 가져오기
        final commentsResponse = await authProvider.getComments(widget.portfolioId, perPage: 15);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            
            if (commentsResponse.success && commentsResponse.data != null) {
              _comments = commentsResponse.data!.comments;
              _currentPage = commentsResponse.data!.pagination.currentPage;
              _lastPage = commentsResponse.data!.pagination.lastPage;
            } else {
              SnackBarHelper.showError(context, commentsResponse.message);
            }
          });
          
          _showSnackBar(
            context,
            isPinned ? '댓글이 고정되었습니다.' : '댓글 고정이 해제되었습니다.',
            isError: false,
          );
        }
      } else {
        SnackBarHelper.showError(context, response.message);
      }
    }
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

  // 댓글 수정 시작 (하단 입력 필드에 표시)
  void _startEditComment(Comment comment) {
    // 대댓글이 있는 경우 수정 불가
    if (comment.repliesCount > 0) {
      _showSnackBar(context, '대댓글이 있는 댓글은 수정할 수 없습니다.', isError: true);
      return;
    }
    
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    // 입력 필드로 포커스 이동
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  // 댓글 수정 취소
  void _cancelEditComment() {
    setState(() {
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Container(
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
                        ? _buildCommentSkeleton()
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
            ),
            // 알림 메시지 (하단, 최상위 레이어)
            if (_snackBarMessage != null)
              Positioned(
                bottom: 70,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8, // 높은 elevation으로 최상위 레이어 보장
                  borderRadius: BorderRadius.circular(12),
                  color: _snackBarIsError ? Colors.red : Colors.green,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: [
                        Icon(
                          _snackBarIsError ? Icons.error_outline : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _snackBarMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() {
                              _snackBarMessage = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
                onPressed: () => Navigator.of(context).pop(_commentAdded),
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

  // 댓글 목록 스켈레톤 UI
  Widget _buildCommentSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: 5, // 스켈레톤 개수
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타 스켈레톤
              Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 텍스트 스켈레톤
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final replies = _repliesMap[comment.id];
    final isExpanded = _repliesExpandedMap[comment.id] == true;
    final isLoading = _repliesLoadingMap[comment.id] == true;
    
    // 현재 사용자가 포트폴리오 작성자인지 확인
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isPortfolioOwner = currentUserId != null && currentUserId == widget.portfolioOwnerId;
    final isCommentOwner = currentUserId != null && currentUserId == comment.user.id;

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
                          const Icon(Icons.push_pin, size: 12, color: Colors.redAccent),
                        ],
                        // 포트폴리오 작성자만 고정 버튼 표시
                        if (isPortfolioOwner) ...[
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              comment.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 16,
                              color: comment.isPinned ? Colors.redAccent : Colors.white,
                            ),
                            onPressed: () => _pinComment(comment.id, !comment.isPinned),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _startReply(comment),
                          child: Text(
                            '답글 달기',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // 본인 댓글이고 대댓글이 없는 경우에만 수정 버튼 표시
                        if (isCommentOwner && comment.repliesCount == 0) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _startEditComment(comment),
                            child: Text(
                              '수정',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
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
    // 현재 사용자가 대댓글 작성자인지 확인
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isReplyOwner = currentUserId != null && currentUserId == reply.user.id;
    
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
              // 본인 대댓글이고 대댓글이 없는 경우에만 수정 버튼 표시
              if (isReplyOwner && reply.repliesCount == 0) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _startEditComment(reply),
                  child: Text(
                    '수정',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
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
          if (_replyingToUsername != null || _editingCommentId != null)
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
                    _editingCommentId != null
                        ? '댓글 수정 중...'
                        : '@$_replyingToUsername 님에게 답글 남기는 중',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_editingCommentId != null) {
                        _cancelEditComment();
                      } else {
                        _cancelReply();
                      }
                    },
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
                  _editingCommentId != null ? '수정' : '게시',
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

