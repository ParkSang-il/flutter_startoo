import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
import '../models/api_response.dart';
import '../models/phone_check_response.dart';
import '../models/portfolio_model.dart';
import '../models/like_response.dart';
import '../models/comment_model.dart';
import '../utils/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // 인증번호 발송
  Future<ApiResponse<void>> sendVerificationCode(String phone) async {
    try {
      final requestData = {'phone': phone};
      
      // 요청 정보 로그
      debugPrint('=== 인증번호 발송 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/phone/send');
      debugPrint('Method: POST');
      debugPrint('Headers: Content-Type: application/json, Accept: application/json');
      debugPrint('Body: $requestData');
      
      final response = await _apiClient.dio.post(
        '/auth/phone/send',
        data: requestData,
      );

      // 응답 데이터 확인 및 로그
      debugPrint('=== 인증번호 발송 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');
      
      if (response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse.fromJson(response.data, null);
        debugPrint('파싱된 응답: success=${apiResponse.success}, message=${apiResponse.message}');
        return apiResponse;
      } else {
        debugPrint('응답 형식 오류: ${response.data.runtimeType}');
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      // 네트워크 에러 또는 서버 에러 처리
      String errorMessage = '인증번호 발송에 실패했습니다.';
      
      if (e.response != null) {
        // 서버에서 에러 응답을 받은 경우
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMessage = data['message'] ?? 
                       data['error'] ?? 
                       '서버 오류가 발생했습니다.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '연결 시간이 초과되었습니다. 네트워크를 확인해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '서버에 연결할 수 없습니다. API URL을 확인해주세요.';
      }
      
      debugPrint('인증번호 발송 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('인증번호 발송 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 인증번호 재전송
  Future<ApiResponse<void>> resendVerificationCode(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/phone/resend',
        data: {'phone': phone},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '인증번호 재전송에 실패했습니다.',
      );
    }
  }

  // 인증번호 검증
  Future<ApiResponse<AuthData>> verifyCode(String phone, String code) async {
    try {
      final requestData = {
        'phone': phone,
        'verification_code': code,
      };
      
      // 요청 정보 로그
      debugPrint('=== 인증번호 검증 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/phone/verify');
      debugPrint('Method: POST');
      debugPrint('Body: $requestData');
      
      final response = await _apiClient.dio.post(
        '/auth/phone/verify',
        data: requestData,
      );

      // 응답 데이터 확인 및 로그
      debugPrint('=== 인증번호 검증 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      // 인증번호 검증 API는 토큰을 반환하지 않음 (단순 성공/실패만)
      // 성공 시 true, 실패 시 false 반환
      final success = response.data['success'] ?? false;
      final message = response.data['message'] ?? '';

      return ApiResponse(
        success: success,
        message: message,
        data: null, // 인증번호 검증은 데이터를 반환하지 않음
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '인증번호 검증에 실패했습니다.',
      );
    }
  }

  // 휴대폰 번호 중복 체크
  Future<ApiResponse<PhoneCheckResponse>> checkPhone(String phone) async {
    try {
      final requestData = {'phone': phone};
      
      debugPrint('=== 휴대폰 중복 체크 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/phone/check');
      debugPrint('Method: POST');
      debugPrint('Body: $requestData');
      
      final response = await _apiClient.dio.post(
        '/auth/phone/check',
        data: requestData,
      );

      debugPrint('=== 휴대폰 중복 체크 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      final phoneCheckResponse = PhoneCheckResponse.fromJson(response.data);
      
      debugPrint('파싱된 응답: success=${phoneCheckResponse.success}, exists=${phoneCheckResponse.exists}, hasUser=${phoneCheckResponse.user != null}');

      return ApiResponse(
        success: phoneCheckResponse.success,
        message: response.data['message'] ?? '',
        data: phoneCheckResponse,
      );
    } on DioException catch (e) {
      debugPrint('휴대폰 중복 체크 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '휴대폰 번호 확인에 실패했습니다.';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMessage = data['message'] ?? errorMessage;
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('휴대폰 중복 체크 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 인증번호 만료 처리
  Future<ApiResponse<void>> expireVerification(String phone) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/phone/expire',
        data: {'phone': phone},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '인증번호 만료 처리에 실패했습니다.',
      );
    }
  }

  // 로그인 (인증 완료 후)
  Future<ApiResponse<AuthData>> login(String phone) async {
    try {
      final requestData = {'phone': phone};
      
      debugPrint('=== 로그인 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/login');
      debugPrint('Method: POST');
      debugPrint('Body: $requestData');
      
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: requestData,
      );

      debugPrint('=== 로그인 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }

      final authResponse = AuthResponse.fromJson(response.data);
      
      debugPrint('파싱된 AuthResponse: success=${authResponse.success}, hasData=${authResponse.data != null}');
      
      if (authResponse.success && authResponse.data != null) {
        if (authResponse.data!.accessToken != null) {
          await _apiClient.saveTokens(
            authResponse.data!.accessToken!,
            null, // refresh_token 없음
          );
          debugPrint('토큰 저장 완료');
        } else {
          debugPrint('경고: accessToken이 null입니다');
        }
      }

      return ApiResponse(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse.data,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '로그인에 실패했습니다.',
      );
    }
  }

  // 회원가입
  Future<ApiResponse<AuthData>> register({
    required String phone,
    required int userType, // 1: 일반, 2: 사업자
    String? nickname,
  }) async {
    try {
      debugPrint('=== 회원가입 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/register');
      debugPrint('Method: POST');
      debugPrint('Body: {phone: $phone, user_type: $userType, nickname: $nickname}');
      
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'phone': phone,
          'user_type': userType,
          if (nickname != null) 'nickname': nickname,
        },
      );

      debugPrint('=== 회원가입 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.data != null) {
        final accessToken = authResponse.data!.accessToken;
        if (accessToken != null) {
          debugPrint('=== 토큰 저장 시작 ===');
          await _apiClient.saveTokens(
            accessToken,
            null, // refresh_token 없음
          );
          debugPrint('토큰 저장 완료');
        } else {
          debugPrint('경고: 회원가입 응답에 토큰이 없습니다.');
        }
      }

      return ApiResponse(
        success: authResponse.success,
        message: authResponse.message,
        data: authResponse.data,
      );
    } on DioException catch (e) {
      debugPrint('회원가입 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '회원가입에 실패했습니다.',
      );
    }
  }

  // 현재 사용자 정보 가져오기
  Future<ApiResponse<User>> getMe() async {
    try {
      debugPrint('=== getMe API 요청 시작 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/me');
      debugPrint('Method: GET');
      debugPrint('Headers: Authorization: Bearer [토큰], Accept: application/json, Content-Type: application/json');
      
      final response = await _apiClient.dio.get('/auth/me').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('=== getMe API 타임아웃 ===');
          throw DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            type: DioExceptionType.connectionTimeout,
            message: '요청 시간이 초과되었습니다.',
          );
        },
      );

      debugPrint('=== getMe API 응답 수신 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }

      final data = response.data['data'];
      debugPrint('data 필드: $data');
      
      if (data == null) {
        return ApiResponse(
          success: response.data['success'] ?? false,
          message: response.data['message'] ?? '사용자 정보가 없습니다.',
        );
      }

      // data 안에 user 객체가 있음
      final userData = data is Map<String, dynamic> ? data['user'] : null;
      
      if (userData == null) {
        return ApiResponse(
          success: response.data['success'] ?? false,
          message: response.data['message'] ?? '사용자 정보가 없습니다.',
        );
      }

      try {
        final user = User.fromJson(userData is Map<String, dynamic> ? userData : {'id': 0, 'user_type': 1});
        debugPrint('User 파싱 성공 - username: ${user.username}, nickname: ${user.nickname}');
        return ApiResponse(
          success: response.data['success'] ?? false,
          message: response.data['message'] ?? '',
          data: user,
        );
      } catch (e) {
        debugPrint('User.fromJson 에러: $e');
        debugPrint('데이터: $userData');
        return ApiResponse(
          success: false,
          message: '사용자 정보 파싱에 실패했습니다: ${e.toString()}',
        );
      }
    } on DioException catch (e) {
      debugPrint('=== getMe DioException 발생 ===');
      debugPrint('에러 타입: ${e.type}');
      debugPrint('에러 메시지: ${e.message}');
      debugPrint('응답 상태 코드: ${e.response?.statusCode}');
      debugPrint('응답 데이터: ${e.response?.data}');
      debugPrint('요청 경로: ${e.requestOptions.path}');
      
      // 타임아웃이나 연결 오류인 경우
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('네트워크 오류 또는 타임아웃 발생');
      }
      
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '사용자 정보를 가져오는데 실패했습니다.',
      );
    } catch (e) {
      debugPrint('=== getMe 예상치 못한 에러 ===');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');
      debugPrint('스택 트레이스: ${StackTrace.current}');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 토큰 리프레시 (access_token을 사용하여 새로운 access_token 받기)
  // 실패 시 토큰 삭제 (호출하는 쪽에서 로그인 화면으로 이동해야 함)
  Future<bool> refreshToken() async {
    try {
      debugPrint('=== 토큰 리프레시 시작 ===');
      final accessToken = await _apiClient.getAccessToken();
      if (accessToken == null) {
        debugPrint('액세스 토큰이 없습니다');
        // 토큰이 없으면 이미 삭제된 상태이므로 false 반환
        return false;
      }

      final response = await _apiClient.dio.post(
        '/auth/refresh',
        data: {'token': accessToken}, // access_token을 사용하여 리프레시
      );

      debugPrint('리프레시 API 응답: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final newAccessToken = data['token'];
        
        if (newAccessToken != null) {
          await _apiClient.saveTokens(newAccessToken, null); // refresh_token 없음
          debugPrint('토큰 리프레시 성공');
          return true;
        }
      }
      
      // 리프레시 실패 시 토큰 삭제
      debugPrint('토큰 리프레시 실패 - 토큰 삭제');
      await _apiClient.clearTokens();
      return false;
    } catch (e) {
      // 리프레시 예외 발생 시 토큰 삭제
      debugPrint('토큰 리프레시 예외 발생: $e - 토큰 삭제');
      await _apiClient.clearTokens();
      return false;
    }
  }

  // 로그아웃
  Future<ApiResponse<void>> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
      await _apiClient.clearTokens();
      
      return ApiResponse(
        success: true,
        message: '로그아웃되었습니다.',
      );
    } on DioException catch (e) {
      await _apiClient.clearTokens();
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '로그아웃에 실패했습니다.',
      );
    }
  }

  // 사업자 추가정보 등록
  Future<ApiResponse<void>> registerBusinessInfo({
    required String businessName,
    required String businessNumber,
    required String? businessCertificate,
    required String? licenseCertificate,
    required String? safetyEducationCertificate,
    required String address,
    String? addressDetail,
    required bool contactPhonePublic,
    required List<String> availableRegions,
    required List<String> mainStyles,
  }) async {
    try {
      debugPrint('=== 사업자 추가정보 등록 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/auth/biz_additional_info');
      debugPrint('Method: POST');
      
      final requestData = {
        'business_name': businessName,
        'business_number': businessNumber,
        if (businessCertificate != null) 'business_certificate': businessCertificate,
        if (licenseCertificate != null) 'license_certificate': licenseCertificate,
        if (safetyEducationCertificate != null) 'safety_education_certificate': safetyEducationCertificate,
        'address': address,
        if (addressDetail != null && addressDetail.isNotEmpty) 'address_detail': addressDetail,
        'contact_phone_public': contactPhonePublic,
        'available_regions': availableRegions,
        'main_styles': mainStyles,
      };
      
      debugPrint('Body: $requestData');
      
      final response = await _apiClient.dio.post(
        '/auth/biz_additional_info',
        data: requestData,
      );

      debugPrint('=== 사업자 추가정보 등록 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }

      final data = response.data;
      return ApiResponse(
        success: data['success'] ?? true,
        message: data['message'] ?? '사업자 추가정보가 등록되었습니다.',
      );
    } on DioException catch (e) {
      debugPrint('사업자 추가정보 등록 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '사업자 추가정보 등록에 실패했습니다.',
      );
    } catch (e) {
      debugPrint('사업자 추가정보 등록 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 피드 리스트 가져오기
  Future<ApiResponse<FeedListResponse>> getFeedList({int page = 1, int perPage = 2}) async {
    try {
      debugPrint('=== 피드 리스트 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios?page=$page&per_page=$perPage');
      debugPrint('Method: GET');

      final response = await _apiClient.dio.get('/portfolios', queryParameters: {
        'page': page,
        'per_page': perPage,
      });

      debugPrint('=== 피드 리스트 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final feedListResponse = FeedListResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint('파싱된 피드 개수: ${feedListResponse.portfolios.length}');

        return ApiResponse(
          success: feedListResponse.success,
          message: '피드 리스트를 성공적으로 가져왔습니다.',
          data: feedListResponse,
        );
      } else {
        return ApiResponse(
          success: false,
          message: '피드 리스트를 가져오는데 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('피드 리스트 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? '피드 리스트를 가져오는데 실패했습니다.',
      );
    } catch (e) {
      debugPrint('피드 리스트 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 포트폴리오 생성
  Future<ApiResponse<void>> createPortfolio({
    required String title,
    required String description,
    required String workDate,
    required int price,
    required bool isPublic,
    required List<Map<String, dynamic>> images,
    required List<String> tags,
  }) async {
    try {
      debugPrint('=== 포트폴리오 생성 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios');
      debugPrint('Method: POST');

      final requestData = {
        'title': title,
        'description': description,
        'work_date': workDate,
        'price': price,
        'is_public': isPublic,
        'images': images,
        'tags': tags,
      };

      debugPrint('Body: $requestData');

      final response = await _apiClient.dio.post(
        '/portfolios',
        data: requestData,
      );

      debugPrint('=== 포트폴리오 생성 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: '포트폴리오가 성공적으로 생성되었습니다.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: '포트폴리오 생성에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('포트폴리오 생성 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      // 422 에러의 경우 errors 필드에서 상세 메시지 추출
      String errorMessage = '포트폴리오 생성에 실패했습니다.';
      if (e.response?.statusCode == 422 && e.response?.data != null) {
        final data = e.response!.data;
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          // 첫 번째 에러 메시지 사용
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0].toString();
            } else if (firstError is String) {
              errorMessage = firstError;
            }
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } else if (e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('포트폴리오 생성 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 포트폴리오 좋아요 추가
  Future<ApiResponse<LikeResponse>> addLike(int portfolioId) async {
    try {
      debugPrint('=== 좋아요 추가 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/like');
      debugPrint('Method: POST');

      final response = await _apiClient.dio.post(
        '/portfolios/$portfolioId/like',
      );

      debugPrint('=== 좋아요 추가 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data,
          (data) => LikeResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('좋아요 추가 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '좋아요 추가에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('좋아요 추가 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 포트폴리오 좋아요 취소
  Future<ApiResponse<LikeResponse>> removeLike(int portfolioId) async {
    try {
      debugPrint('=== 좋아요 취소 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/like');
      debugPrint('Method: DELETE');

      final response = await _apiClient.dio.delete(
        '/portfolios/$portfolioId/like',
      );

      debugPrint('=== 좋아요 취소 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data,
          (data) => LikeResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('좋아요 취소 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '좋아요 취소에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('좋아요 취소 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 포트폴리오 좋아요 토글 (기존 호환성 유지)
  Future<ApiResponse<LikeResponse>> toggleLike(int portfolioId, bool currentLikeStatus) async {
    if (currentLikeStatus) {
      return await removeLike(portfolioId);
    } else {
      return await addLike(portfolioId      );
    }
  }

  // 포트폴리오 댓글 목록 조회 (상위 댓글만)
  Future<ApiResponse<CommentListResponse>> getComments(int portfolioId, {int perPage = 15}) async {
    try {
      debugPrint('=== 댓글 목록 조회 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments');
      debugPrint('Method: GET');

      final response = await _apiClient.dio.get(
        '/portfolios/$portfolioId/comments',
        queryParameters: {'per_page': perPage},
      );

      debugPrint('=== 댓글 목록 조회 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data,
          (data) => CommentListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('댓글 목록 조회 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '댓글 목록을 불러오는데 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('댓글 목록 조회 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 대댓글 목록 조회
  Future<ApiResponse<ReplyListResponse>> getReplies(int portfolioId, int commentId, {int perPage = 20}) async {
    try {
      debugPrint('=== 대댓글 목록 조회 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments/$commentId/replies');
      debugPrint('Method: GET');

      final response = await _apiClient.dio.get(
        '/portfolios/$portfolioId/comments/$commentId/replies',
        queryParameters: {'per_page': perPage},
      );

      debugPrint('=== 대댓글 목록 조회 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          response.data,
          (data) => ReplyListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('대댓글 목록 조회 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '대댓글 목록을 불러오는데 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('대댓글 목록 조회 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 댓글 작성
  Future<ApiResponse<Comment>> createComment(int portfolioId, String content, {int? parentId}) async {
    try {
      debugPrint('=== 댓글 작성 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments');
      debugPrint('Method: POST');

      final requestData = {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      };

      final response = await _apiClient.dio.post(
        '/portfolios/$portfolioId/comments',
        data: requestData,
      );

      debugPrint('=== 댓글 작성 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.fromJson(
          data,
          (commentData) => Comment.fromJson(commentData['comment'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('댓글 작성 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '댓글 작성에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('댓글 작성 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 댓글 수정
  Future<ApiResponse<Comment>> updateComment(int portfolioId, int commentId, String content) async {
    try {
      debugPrint('=== 댓글 수정 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments/$commentId');
      debugPrint('Method: PUT');

      final response = await _apiClient.dio.put(
        '/portfolios/$portfolioId/comments/$commentId',
        data: {'content': content},
      );

      debugPrint('=== 댓글 수정 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.fromJson(
          data,
          (commentData) => Comment.fromJson(commentData['comment'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('댓글 수정 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '댓글 수정에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('댓글 수정 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 댓글 삭제
  Future<ApiResponse<void>> deleteComment(int portfolioId, int commentId) async {
    try {
      debugPrint('=== 댓글 삭제 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments/$commentId');
      debugPrint('Method: DELETE');

      final response = await _apiClient.dio.delete(
        '/portfolios/$portfolioId/comments/$commentId',
      );

      debugPrint('=== 댓글 삭제 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data, null);
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('댓글 삭제 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '댓글 삭제에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('댓글 삭제 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 댓글 고정/해제
  Future<ApiResponse<Comment>> pinComment(int portfolioId, int commentId, bool isPinned) async {
    try {
      debugPrint('=== 댓글 고정/해제 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/comments/$commentId/pin');
      debugPrint('Method: POST');

      final response = await _apiClient.dio.post(
        '/portfolios/$portfolioId/comments/$commentId/pin',
        data: {'is_pinned': isPinned},
      );

      debugPrint('=== 댓글 고정/해제 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // 응답 구조: {success: true, message: "...", data: {comment: {id: 6, is_pinned: true}}}
        final responseData = data['data'] as Map<String, dynamic>?;
        final commentData = responseData?['comment'] as Map<String, dynamic>?;
        
        if (commentData != null) {
          // 최소한의 Comment 객체 생성 (필수 필드만)
          final comment = Comment(
            id: commentData['id'] ?? 0,
            portfolioId: portfolioId,
            parentId: null,
            content: '', // 응답에 없으므로 기본값
            isPinned: commentData['is_pinned'] ?? false,
            createdAt: '', // 응답에 없으므로 기본값
            updatedAt: '', // 응답에 없으므로 기본값
            user: CommentUser(
              id: 0,
              username: '',
              profileImage: '',
              userType: 0,
            ), // 응답에 없으므로 기본값
            repliesCount: 0, // 응답에 없으므로 기본값
          );
          return ApiResponse(
            success: data['success'] ?? false,
            message: data['message'] ?? '',
            data: comment,
          );
        } else {
          // comment 데이터가 없어도 성공 응답이면 성공으로 처리 (댓글 목록을 다시 로드하므로)
          return ApiResponse(
            success: data['success'] ?? false,
            message: data['message'] ?? '',
            data: null,
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('댓글 고정/해제 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '댓글 고정/해제에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('댓글 고정/해제 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 포트폴리오 신고
  Future<ApiResponse<void>> reportPortfolio(int portfolioId) async {
    try {
      debugPrint('=== 포트폴리오 신고 API 요청 ===');
      debugPrint('URL: ${ApiClient.baseUrl}/portfolios/$portfolioId/report');
      debugPrint('Method: POST');

      final response = await _apiClient.dio.post(
        '/portfolios/$portfolioId/report',
      );

      debugPrint('=== 포트폴리오 신고 API 응답 ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('응답 데이터: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? '신고가 완료되었습니다.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: '서버 응답 형식이 올바르지 않습니다.',
        );
      }
    } on DioException catch (e) {
      debugPrint('포트폴리오 신고 API 에러: ${e.type}, ${e.message}');
      debugPrint('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '신고에 실패했습니다.';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      debugPrint('포트폴리오 신고 예상치 못한 에러: $e');
      return ApiResponse(
        success: false,
        message: '예상치 못한 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }
}

