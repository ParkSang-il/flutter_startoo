import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 인터셉터 추가: JWT 토큰 자동 추가 및 리프레시
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 요청 전에 토큰 추가
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 에러 시 토큰 리프레시 시도
        if (error.response?.statusCode == 401) {
          debugPrint('=== 인터셉터: 401 에러 감지 - 토큰 리프레시 시도 ===');
          
          // 리프레시 요청 자체인 경우 무한 루프 방지
          if (error.requestOptions.path == '/auth/refresh') {
            debugPrint('=== 인터셉터: 리프레시 요청 자체가 401 - 토큰 삭제 및 에러 전달 ===');
            await _storage.deleteAll();
            return handler.next(error);
          }
          
          // 토큰 리프레시 시도
          final refreshed = await _refreshToken();
          
          if (refreshed) {
            debugPrint('=== 인터셉터: 토큰 리프레시 성공 - 원래 요청 재시도 ===');
            // 리프레시 성공 시 원래 요청 재시도
            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(error.requestOptions);
                debugPrint('=== 인터셉터: 재시도 성공 ===');
                return handler.resolve(response);
              } catch (e) {
                debugPrint('=== 인터셉터: 재시도 실패: $e ===');
                return handler.next(error);
              }
            }
          } else {
            debugPrint('=== 인터셉터: 토큰 리프레시 실패 - 토큰 삭제 및 에러 전달 ===');
            // 리프레시 실패 시 토큰 삭제 (이미 _refreshToken에서 삭제됨)
            // 에러 전달하여 호출하는 쪽에서 로그인 화면으로 이동하도록 함
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'token': accessToken}, // access_token을 사용하여 리프레시
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final newAccessToken = data['token'];
        
        if (newAccessToken != null) {
          await _storage.write(key: 'access_token', value: newAccessToken);
          return true;
        }
      }
      // 리프레시 실패 시 토큰 삭제
      await _storage.deleteAll();
      return false;
    } catch (e) {
      // 리프레시 예외 발생 시 토큰 삭제
      await _storage.deleteAll();
      return false;
    }
  }

  Dio get dio => _dio;

  // 토큰 저장 (refresh_token 없음)
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    // refresh_token은 사용하지 않음
  }
  
  // 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // 토큰 삭제
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    // refresh_token은 사용하지 않음
  }

  // 토큰 확인
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}

