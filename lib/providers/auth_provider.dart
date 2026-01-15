import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
import '../models/api_response.dart';
import '../models/portfolio_model.dart';
import '../models/like_response.dart';
import '../models/comment_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  String? _verificationToken; // 인증 완료 후 토큰 저장

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String? get verificationToken => _verificationToken;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 인증번호 발송
  Future<bool> sendVerificationCode(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.sendVerificationCode(phone);
      _setLoading(false);

      if (!response.success) {
        final errorMsg = response.message.isNotEmpty 
            ? response.message 
            : '인증번호 발송에 실패했습니다.';
        _setError(errorMsg);
        debugPrint('인증번호 발송 실패: $errorMsg');
        return false;
      }

      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint('인증번호 발송 예외 발생: $e');
      _setError('인증번호 발송 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }

  // 인증번호 재전송
  Future<bool> resendVerificationCode(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.resendVerificationCode(phone);
      _setLoading(false);

      if (!response.success) {
        _setError(response.message);
        return false;
      }

      return true;
    } catch (e) {
      _setLoading(false);
      _setError('인증번호 재전송 중 오류가 발생했습니다.');
      return false;
    }
  }

  // 인증번호 검증
  Future<bool> verifyCode(String phone, String code, {bool isRegister = false}) async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('=== 인증번호 검증 시작 ===');
      debugPrint('Phone: $phone, Code: $code, isRegister: $isRegister');
      
      final response = await _authService.verifyCode(phone, code);

      _setLoading(false);

      debugPrint('검증 응답: success=${response.success}');

      if (!response.success) {
        debugPrint('검증 실패: ${response.message}');
        _setError(response.message);
        return false;
      }

      // 인증번호 검증 성공 후 휴대폰 중복 체크
      debugPrint('=== 휴대폰 중복 체크 시작 ===');
      final checkResponse = await _authService.checkPhone(phone);
      
      if (!checkResponse.success || checkResponse.data == null) {
        debugPrint('휴대폰 중복 체크 실패: ${checkResponse.message}');
        _setError(checkResponse.message);
        return false;
      }

      // 로그인 플로우(isRegister: false)일 때만 로그인 로직 실행
      if (!isRegister) {
        // 기존 사용자인 경우 (exists: true)
        if (checkResponse.data!.exists && checkResponse.data!.user != null) {
          debugPrint('기존 사용자 확인 - 로그인 처리');
          
          // 로그인 API 호출하여 토큰 받기 (phone만 전송)
          final loginResponse = await _authService.login(phone);
          if (loginResponse.success && loginResponse.data != null) {
            _currentUser = loginResponse.data!.user;
            debugPrint('로그인 성공 - 사용자 정보 업데이트');
            return true;
          } else {
            debugPrint('로그인 API 실패: ${loginResponse.message}');
            // 로그인 실패 시 중복 체크에서 받은 사용자 정보라도 사용
            _currentUser = checkResponse.data!.user;
            _setError(loginResponse.message);
            return false;
          }
        } else {
          // 신규 사용자인 경우 에러 (로그인 플로우인데 가입되지 않은 번호)
          debugPrint('신규 사용자 확인 - 로그인 불가');
          _setError('가입되지 않은 번호입니다. 회원가입을 진행해주세요.');
          return false;
        }
      } else {
        // 회원가입 플로우(isRegister: true)일 때
        if (checkResponse.data!.exists && checkResponse.data!.user != null) {
          // 기존 사용자인 경우 에러 (이미 가입된 번호)
          debugPrint('기존 사용자 확인 - 회원가입 불가');
          _setError('이미 가입된 번호입니다. 로그인을 진행해주세요.');
          return false;
        } else {
          // 신규 사용자인 경우 회원가입 플로우로 이동
          debugPrint('신규 사용자 확인 - 회원가입 플로우로 이동');
          return true;
        }
      }
    } catch (e) {
      _setLoading(false);
      debugPrint('인증번호 검증 예외 발생: $e');
      _setError('인증번호 검증 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }


  // 회원가입
  Future<bool> register({
    required String phone,
    required int userType,
    String? nickname,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(
        phone: phone,
        userType: userType,
        nickname: nickname,
      );
      _setLoading(false);

      if (!response.success || response.data == null) {
        _setError(response.message);
        return false;
      }

      _currentUser = response.data!.user;
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('회원가입 중 오류가 발생했습니다.');
      return false;
    }
  }

  // 로그아웃
  Future<bool> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.logout();
      _setLoading(false);

      if (!response.success) {
        _setError(response.message);
        return false;
      }

      _currentUser = null;
      _verificationToken = null;
      return true;
    } catch (e) {
      _setLoading(false);
      _currentUser = null;
      _verificationToken = null;
      return true; // 로그아웃은 항상 성공으로 처리
    }
  }

  // 현재 사용자 정보 가져오기 (자동 로그인용)
  Future<bool> getMe() async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('=== AuthProvider.getMe 시작 ===');
      final response = await _authService.getMe();
      debugPrint('=== AuthProvider.getMe 응답 받음 ===');
      debugPrint('성공 여부: ${response.success}');
      debugPrint('메시지: ${response.message}');
      debugPrint('데이터 존재 여부: ${response.data != null}');
      
      _setLoading(false);

      if (!response.success || response.data == null) {
        debugPrint('=== getMe 실패 ===');
        debugPrint('실패 메시지: ${response.message}');
        // 401 에러는 인터셉터에서 이미 토큰 삭제 처리됨
        // 여기서는 바로 실패 처리
        _currentUser = null;
        debugPrint('=== getMe 실패 - 사용자 정보 null 설정 ===');
        return false;
      }

      _currentUser = response.data;
      debugPrint('=== getMe 성공 - 사용자 정보 설정 완료 ===');
      debugPrint('사용자 ID: ${_currentUser?.id}');
      debugPrint('사용자 이름: ${_currentUser?.username}');
      return true;
    } catch (e, stackTrace) {
      _setLoading(false);
      debugPrint('=== AuthProvider.getMe 예외 발생 ===');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');
      debugPrint('스택 트레이스: $stackTrace');
      _currentUser = null;
      return false;
    }
  }

  // 사용자 정보 업데이트
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // 사업자 추가정보 등록
  Future<Map<String, dynamic>> registerBusinessInfo({
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
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('=== AuthProvider.registerBusinessInfo 시작 ===');
      final response = await _authService.registerBusinessInfo(
        businessName: businessName,
        businessNumber: businessNumber,
        businessCertificate: businessCertificate,
        licenseCertificate: licenseCertificate,
        safetyEducationCertificate: safetyEducationCertificate,
        address: address,
        addressDetail: addressDetail,
        contactPhonePublic: contactPhonePublic,
        availableRegions: availableRegions,
        mainStyles: mainStyles,
      );
      
      _setLoading(false);

      if (!response.success) {
        debugPrint('사업자 추가정보 등록 실패: ${response.message}');
        _setError(response.message);
        return {
          'success': false,
          'message': response.message,
        };
      }

      debugPrint('=== 사업자 추가정보 등록 성공 ===');
      return {
        'success': true,
        'message': response.message ?? '사업자 정보가 등록되었습니다.',
      };
    } catch (e) {
      _setLoading(false);
      debugPrint('사업자 추가정보 등록 예외 발생: $e');
      final errorMessage = '사업자 추가정보 등록 중 오류가 발생했습니다.';
      _setError(errorMessage);
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // 피드 리스트 가져오기
  Future<ApiResponse<FeedListResponse>> getFeedList({int page = 1, int perPage = 2}) async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('=== AuthProvider.getFeedList 시작 ===');
      final response = await _authService.getFeedList(page: page, perPage: perPage);
      _setLoading(false);

      if (!response.success) {
        debugPrint('피드 리스트 가져오기 실패: ${response.message}');
        _setError(response.message);
        return response;
      }

      debugPrint('=== 피드 리스트 가져오기 성공 ===');
      debugPrint('피드 개수: ${response.data?.portfolios.length ?? 0}');
      return response;
    } catch (e) {
      _setLoading(false);
      debugPrint('피드 리스트 호출 예외 발생: $e');
      final errorMessage = '피드 리스트 호출에 실패하였습니다. 잠시 후 다시 시도해 주세요.';
      _setError(errorMessage);
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  // 포트폴리오 좋아요 추가
  Future<ApiResponse<LikeResponse>> addLike(int portfolioId) async {
    return await _authService.addLike(portfolioId);
  }

  // 포트폴리오 좋아요 취소
  Future<ApiResponse<LikeResponse>> removeLike(int portfolioId) async {
    return await _authService.removeLike(portfolioId);
  }

  // 포트폴리오 좋아요 토글 (기존 호환성 유지)
  Future<ApiResponse<LikeResponse>> toggleLike(int portfolioId, bool currentLikeStatus) async {
    return await _authService.toggleLike(portfolioId, currentLikeStatus);
  }

  // 댓글 목록 조회
  Future<ApiResponse<CommentListResponse>> getComments(int portfolioId, {int perPage = 15}) async {
    return await _authService.getComments(portfolioId, perPage: perPage);
  }

  // 대댓글 목록 조회
  Future<ApiResponse<ReplyListResponse>> getReplies(int portfolioId, int commentId, {int perPage = 20}) async {
    return await _authService.getReplies(portfolioId, commentId, perPage: perPage);
  }

  // 댓글 작성
  Future<ApiResponse<Comment>> createComment(int portfolioId, String content, {int? parentId}) async {
    return await _authService.createComment(portfolioId, content, parentId: parentId);
  }

  // 댓글 수정
  Future<ApiResponse<Comment>> updateComment(int portfolioId, int commentId, String content) async {
    return await _authService.updateComment(portfolioId, commentId, content);
  }

  // 댓글 삭제
  Future<ApiResponse<void>> deleteComment(int portfolioId, int commentId) async {
    return await _authService.deleteComment(portfolioId, commentId);
  }

  // 댓글 고정/해제
  Future<ApiResponse<Comment>> pinComment(int portfolioId, int commentId, bool isPinned) async {
    return await _authService.pinComment(portfolioId, commentId, isPinned);
  }

  // 포트폴리오 신고
  Future<ApiResponse<void>> reportPortfolio(int portfolioId) async {
    return await _authService.reportPortfolio(portfolioId);
  }
}

