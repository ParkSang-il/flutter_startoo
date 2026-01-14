import 'dart:io';

class ApiConfig {
  // Android 에뮬레이터에서는 10.0.2.2를 사용해야 호스트 머신의 localhost에 접근 가능
  // 실제 Android 기기를 사용하는 경우 PC의 IP 주소를 사용해야 합니다 (예: http://192.168.0.100:8000/api)
  // iOS 시뮬레이터나 실제 iOS 기기에서는 localhost 사용 가능
  // 프로덕션에서는 실제 서버 주소로 변경하세요
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android 에뮬레이터: 10.0.2.2는 호스트 머신의 localhost를 가리킵니다
      // 실제 Android 기기 사용 시: PC의 IP 주소로 변경하세요 (예: 'http://192.168.0.100:8000/api')
      return 'http://220.118.162.20/api';
    } else {
      // iOS 시뮬레이터 또는 실제 iOS 기기
      return 'http://220.118.162.20/api';
    }
  }
  
  // API 타임아웃 설정 (초)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}

