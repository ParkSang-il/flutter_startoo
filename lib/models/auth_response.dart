class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

class AuthData {
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final bool? isExistingUser; // 기존 사용자 여부
  final String? verificationToken; // 인증 토큰 (회원가입 시 사용)

  AuthData({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.isExistingUser,
    this.verificationToken,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      // API에서 token 또는 access_token으로 반환될 수 있음
      accessToken: json['token'] ?? json['access_token'],
      refreshToken: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      isExistingUser: json['is_existing_user'],
      verificationToken: json['verification_token'],
    );
  }
}

class User {
  final int id;
  final String? nickname;
  final String? username; // API에서 반환하는 username
  final String? phone;
  final String? profileImage;
  final int userType; // 1: 일반, 2: 사업자
  final String? email;

  User({
    required this.id,
    this.nickname,
    this.username,
    this.phone,
    this.profileImage,
    required this.userType,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // null인 경우 0으로 기본값 설정
      nickname: json['nickname'],
      username: json['username'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      userType: json['user_type'] ?? 1, // null인 경우 1(일반 회원)으로 기본값 설정
      email: json['email'],
    );
  }
}

