// lib/models/feed_model.dart (예시 경로)
class FeedModel {
  final int portfolioId;
  final int portfolioOwnerId; // 포트폴리오 작성자 ID
  final String username;
  final String userImage;
  final String postImage; // 하위 호환성을 위해 유지
  final List<String> postImages; // 이미지 리스트 추가
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final int userType;
  final String businessName;
  final bool isLiked;

  FeedModel({
    required this.portfolioId,
    required this.portfolioOwnerId,
    required this.username,
    required this.userImage,
    required this.postImage,
    required this.postImages, // 이미지 리스트 필수
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.userType,
    required this.businessName,
    this.isLiked = false,
  });
}