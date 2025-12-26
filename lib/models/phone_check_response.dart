import 'auth_response.dart';

class PhoneCheckResponse {
  final bool success;
  final bool exists;
  final User? user;

  PhoneCheckResponse({
    required this.success,
    required this.exists,
    this.user,
  });

  factory PhoneCheckResponse.fromJson(Map<String, dynamic> json) {
    return PhoneCheckResponse(
      success: json['success'] ?? false,
      exists: json['exists'] ?? false,
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
    );
  }
}

