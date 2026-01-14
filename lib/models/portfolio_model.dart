// Portfolio 관련 모델들
class PortfolioImage {
  final int id;
  final int portfolioId;
  final String imageUrl;
  final int imageOrder;
  final String scale;
  final String offsetX;
  final String offsetY;

  PortfolioImage({
    required this.id,
    required this.portfolioId,
    required this.imageUrl,
    required this.imageOrder,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  factory PortfolioImage.fromJson(Map<String, dynamic> json) {
    return PortfolioImage(
      id: json['id'] ?? 0,
      portfolioId: json['portfolio_id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      imageOrder: json['image_order'] ?? 0,
      scale: json['scale'] ?? '1.0',
      offsetX: json['offset_x'] ?? '0.0',
      offsetY: json['offset_y'] ?? '0.0',
    );
  }
}

class PortfolioTag {
  final int id;
  final String name;
  final int usageCount;

  PortfolioTag({
    required this.id,
    required this.name,
    required this.usageCount,
  });

  factory PortfolioTag.fromJson(Map<String, dynamic> json) {
    return PortfolioTag(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      usageCount: json['usage_count'] ?? 0,
    );
  }
}

class PortfolioUser {
  final int id;
  final String username;
  final String profileImage;
  final int userType;

  PortfolioUser({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.userType,
  });

  factory PortfolioUser.fromJson(Map<String, dynamic> json) {
    return PortfolioUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profileImage: json['profile_image'] ?? '',
      userType: json['user_type'] ?? '',
    );
  }
}

class PortfolioBusiness {
  final int id;
  final int userId;
  final String businessName;

  PortfolioBusiness({
    required this.id,
    required this.userId,
    required this.businessName
  });

  factory PortfolioBusiness.fromJson(Map<String, dynamic> json) {
    return PortfolioBusiness(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      businessName: json['business_name'] ?? ''
    );
  }
}

class Portfolio {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String workDate;
  final String price;
  final bool isPublic;
  final bool isSensitive;
  final int views;
  final int likesCount;
  final int commentsCount;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<PortfolioImage> images;
  final List<PortfolioTag> tags;
  final PortfolioUser user;
  final PortfolioBusiness business;
  final bool isLiked;

  Portfolio({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.workDate,
    required this.price,
    required this.isPublic,
    required this.isSensitive,
    required this.views,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.images,
    required this.tags,
    required this.user,
    required this.business,
    this.isLiked = false,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    print(json);
    return Portfolio(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      workDate: json['work_date'] ?? '',
      price: json['price'] ?? '0.00',
      isPublic: json['is_public'] ?? true,
      isSensitive: json['is_sensitive'] ?? false,
      views: json['views'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      images: (json['images'] as List<dynamic>?)
              ?.map((item) => PortfolioImage.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((item) => PortfolioTag.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      user: PortfolioUser.fromJson(json['user'] as Map<String, dynamic>),
      business: PortfolioBusiness.fromJson(json['business_verification'] as Map<String, dynamic>),
      isLiked: json['is_liked'] ?? false,
    );
  }

  // 첫 번째 이미지 URL 가져오기 (피드 표시용)
  String get firstImageUrl {
    if (images.isEmpty) return '';
    return images.first.imageUrl;
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
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}

class FeedListResponse {
  final bool success;
  final List<Portfolio> portfolios;
  final Pagination pagination;

  FeedListResponse({
    required this.success,
    required this.portfolios,
    required this.pagination,
  });

  factory FeedListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final portfoliosList = data?['portfolios'] as List<dynamic>? ?? [];
    final paginationData = data?['pagination'] as Map<String, dynamic>?;

    return FeedListResponse(
      success: json['success'] ?? false,
      portfolios: portfoliosList
          .map((item) => Portfolio.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: paginationData != null
          ? Pagination.fromJson(paginationData)
          : Pagination(
              currentPage: 1,
              lastPage: 1,
              perPage: 10,
              total: 0,
            ),
    );
  }
}

