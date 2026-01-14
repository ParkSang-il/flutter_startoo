class LikeResponse {
  final int likesCount;
  final bool isLiked;

  LikeResponse({
    required this.likesCount,
    required this.isLiked,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }
}

