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

// 미디어 타입 (이미지/비디오 통합)
class PortfolioMedia {
  final String type; // "image" or "video"
  final int id;
  final String? imageUrl;
  final int? imageOrder;
  final String? scale;
  final String? offsetX;
  final String? offsetY;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final String? videoFilePath; // video_file_path (콜백 전에는 이것만 있을 수 있음)
  final String? videoStatus; // video_status (complete, encoding, 등)
  final int? videoOrder;
  final int order; // 전체 순서
  final String createdAt;

  PortfolioMedia({
    required this.type,
    required this.id,
    this.imageUrl,
    this.imageOrder,
    this.scale,
    this.offsetX,
    this.offsetY,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoFilePath,
    this.videoStatus,
    this.videoOrder,
    required this.order,
    required this.createdAt,
  });

  factory PortfolioMedia.fromJson(Map<String, dynamic> json) {
    return PortfolioMedia(
      type: json['type'] ?? 'image',
      id: json['id'] ?? 0,
      imageUrl: json['image_url'],
      imageOrder: json['image_order'],
      scale: json['scale'],
      offsetX: json['offset_x'],
      offsetY: json['offset_y'],
      videoUrl: json['video_url'],
      videoThumbnailUrl: json['video_thumbnail_url'],
      videoFilePath: json['video_file_path'],
      videoStatus: json['video_status'],
      videoOrder: json['video_order'],
      order: json['order'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isVideoComplete => videoStatus == 'complete';
  bool get isVideoEncoding => videoStatus != null && videoStatus != 'complete';

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
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
  final List<PortfolioImage> images; // 하위 호환성을 위해 유지
  final List<PortfolioMedia> media; // 새로운 media 배열
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
    required this.media,
    required this.tags,
    required this.user,
    required this.business,
    this.isLiked = false,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    print(json);
    
    // media 배열 파싱
    final mediaList = (json['media'] as List<dynamic>?)
        ?.map((item) => PortfolioMedia.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];
    
    // 하위 호환성을 위해 images 배열도 파싱 (media에서 이미지만 추출)
    final imageList = mediaList
        .where((m) => m.isImage && m.imageUrl != null)
        .map((m) => PortfolioImage(
              id: m.id,
              portfolioId: json['id'] ?? 0,
              imageUrl: m.imageUrl!,
              imageOrder: m.imageOrder ?? 0,
              scale: m.scale ?? '1.0',
              offsetX: m.offsetX ?? '0.0',
              offsetY: m.offsetY ?? '0.0',
            ))
        .toList();
    
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
      images: imageList,
      media: mediaList,
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

