class ArtistProfileResponse {
  final bool success;
  final String message;
  final ArtistProfileData? data;

  ArtistProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ArtistProfileResponse.fromJson(Map<String, dynamic> json) {
    return ArtistProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ArtistProfileData.fromJson(json['data']) : null,
    );
  }
}

class ArtistProfileData {
  final ArtistUser user;
  final ArtistProfile? artistProfile;
  final BusinessVerification? businessVerification;
  final FollowInfo followInfo;

  ArtistProfileData({
    required this.user,
    this.artistProfile,
    this.businessVerification,
    required this.followInfo,
  });

  factory ArtistProfileData.fromJson(Map<String, dynamic> json) {
    return ArtistProfileData(
      user: ArtistUser.fromJson(json['user']),
      artistProfile: json['artist_profile'] != null 
          ? ArtistProfile.fromJson(json['artist_profile']) 
          : null,
      businessVerification: json['business_verification'] != null
          ? BusinessVerification.fromJson(json['business_verification'])
          : null,
      followInfo: FollowInfo.fromJson(json['follow_info']),
    );
  }
}

class ArtistUser {
  final int id;
  final String username;
  final String? profileImage;
  final int userType;

  ArtistUser({
    required this.id,
    required this.username,
    this.profileImage,
    required this.userType,
  });

  factory ArtistUser.fromJson(Map<String, dynamic> json) {
    return ArtistUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      profileImage: json['profile_image'],
      userType: json['user_type'] ?? 1,
    );
  }
}

class ArtistProfile {
  final int id;
  final String? coverImage;
  final String? artistName;
  final String? email;
  final String? instagram;
  final String? website;
  final String? studioAddress;
  final String? bio;
  final String createdAt;
  final String updatedAt;

  ArtistProfile({
    required this.id,
    this.coverImage,
    this.artistName,
    this.email,
    this.instagram,
    this.website,
    this.studioAddress,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    return ArtistProfile(
      id: json['id'] ?? 0,
      coverImage: json['cover_image'],
      artistName: json['artist_name'],
      email: json['email'],
      instagram: json['instagram'],
      website: json['website'],
      studioAddress: json['studio_address'],
      bio: json['bio'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class BusinessVerification {
  final int id;
  final String? businessName;
  final String? businessNumber;
  final String? address;
  final String? addressDetail;
  final bool contactPhonePublic;
  final List<String> availableRegions;
  final List<String> mainStyles;
  final String status;
  final String? approvedAt;

  BusinessVerification({
    required this.id,
    this.businessName,
    this.businessNumber,
    this.address,
    this.addressDetail,
    required this.contactPhonePublic,
    required this.availableRegions,
    required this.mainStyles,
    required this.status,
    this.approvedAt,
  });

  factory BusinessVerification.fromJson(Map<String, dynamic> json) {
    return BusinessVerification(
      id: json['id'] ?? 0,
      businessName: json['business_name'],
      businessNumber: json['business_number'],
      address: json['address'],
      addressDetail: json['address_detail'],
      contactPhonePublic: json['contact_phone_public'] ?? true,
      availableRegions: json['available_regions'] != null
          ? List<String>.from(json['available_regions'])
          : [],
      mainStyles: json['main_styles'] != null
          ? List<String>.from(json['main_styles'])
          : [],
      status: json['status'] ?? '',
      approvedAt: json['approved_at'],
    );
  }
}

class FollowInfo {
  final int followerCount;
  final int followingCount;
  final bool isFollowing;

  FollowInfo({
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory FollowInfo.fromJson(Map<String, dynamic> json) {
    return FollowInfo(
      followerCount: json['follower_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
    );
  }
}

// 일반회원 프로필 응답
class UserProfileResponse {
  final bool success;
  final String message;
  final UserProfileData? data;

  UserProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserProfileData.fromJson(json['data']) : null,
    );
  }
}

class UserProfileData {
  final ArtistUser user;
  final FollowInfo followInfo;

  UserProfileData({
    required this.user,
    required this.followInfo,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      user: ArtistUser.fromJson(json['user']),
      followInfo: FollowInfo.fromJson(json['follow_info']),
    );
  }
}

