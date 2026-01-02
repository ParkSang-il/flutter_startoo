import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
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
    if (_verificationToken == null) {
      _setError('인증이 완료되지 않았습니다.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(
        phone: phone,
        verificationToken: _verificationToken!,
        userType: userType,
        nickname: nickname,
      );
      _setLoading(false);

      if (!response.success || response.data == null) {
        _setError(response.message);
        return false;
      }

      _currentUser = response.data!.user;
      _verificationToken = null; // 회원가입 완료 후 토큰 제거
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
      debugPrint('=== 사용자 정보 가져오기 시작 ===');
      final response = await _authService.getMe();
      _setLoading(false);

      if (!response.success || response.data == null) {
        debugPrint('getMe 실패: ${response.message}');
        
        // 토큰이 만료되었을 수 있으므로 리프레시 시도
        debugPrint('토큰 리프레시 시도...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          debugPrint('토큰 리프레시 성공 - getMe 재시도');
          // 리프레시 성공 시 다시 getMe 호출
          final retryResponse = await _authService.getMe();
          if (retryResponse.success && retryResponse.data != null) {
            _currentUser = retryResponse.data;
            debugPrint('getMe 재시도 성공');
            return true;
          }
        } else {
          debugPrint('토큰 리프레시 실패');
        }
        
        // 리프레시도 실패하면 사용자 정보를 null로 설정
        _currentUser = null;
        return false;
      }

      _currentUser = response.data;
      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint('getMe 예외 발생: $e');
      _currentUser = null;
      return false;
    }
  }

  // 사용자 정보 업데이트
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }
}

