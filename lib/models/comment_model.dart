class CommentUser {
  final int id;
  final String username;
  final String profileImage;
  final int userType;

  CommentUser({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.userType,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profileImage: json['profile_image'] ?? '',
      userType: json['user_type'] is int ? json['user_type'] : (json['user_type'] is String ? int.tryParse(json['user_type']) ?? 0 : 0),
    );
  }
}

class Comment {
  final int id;
  final int portfolioId;
  final int? parentId;
  final String content;
  final bool isPinned;
  final String createdAt;
  final String updatedAt;
  final CommentUser user;
  final int repliesCount;
  final List<Comment>? replies; // 대댓글 목록 (선택적)

  Comment({
    required this.id,
    required this.portfolioId,
    this.parentId,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.repliesCount,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      portfolioId: json['portfolio_id'] ?? 0,
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
      repliesCount: json['replies_count'] ?? 0,
      replies: json['replies'] != null
          ? (json['replies'] as List<dynamic>)
              .map((reply) => Comment.fromJson(reply as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  // 시간 표시용 (created_at을 "N시간 전" 형식으로 변환)
  String get timeAgo {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return createdAt;
    }
  }
}

class CommentListResponse {
  final List<Comment> comments;
  final Pagination pagination;

  CommentListResponse({
    required this.comments,
    required this.pagination,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    return CommentListResponse(
      comments: (json['comments'] as List<dynamic>?)
              ?.map((comment) => Comment.fromJson(comment as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class ReplyListResponse {
  final List<Comment> replies;
  final Pagination pagination;

  ReplyListResponse({
    required this.replies,
    required this.pagination,
  });

  factory ReplyListResponse.fromJson(Map<String, dynamic> json) {
    return ReplyListResponse(
      replies: (json['replies'] as List<dynamic>?)
              ?.map((reply) => Comment.fromJson(reply as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
    );
  }
}

