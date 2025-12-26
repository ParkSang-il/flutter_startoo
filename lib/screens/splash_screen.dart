import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../providers/auth_provider.dart';
import '../utils/api_client.dart';
import 'home_screen.dart';
import 'auth/login_or_register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 네이티브 스플래시가 표시되는 동안 인증 체크 수행
    final apiClient = ApiClient();
    final hasToken = await apiClient.hasToken();

    if (!mounted) return;

    // 토큰이 있으면 사용자 정보 가져오기 시도 (리프레시 포함)
    if (hasToken) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.getMe();

      if (mounted) {
        if (success && authProvider.isAuthenticated) {
          // 인증 체크 완료 후 네이티브 스플래시 제거
          FlutterNativeSplash.remove();
          // 사용자 정보를 성공적으로 가져왔으면 홈으로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // 토큰이 유효하지 않고 리프레시도 실패한 경우 로그인 화면으로
          // 토큰 삭제
          await apiClient.clearTokens();
          // 인증 체크 완료 후 네이티브 스플래시 제거
          FlutterNativeSplash.remove();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
          );
        }
      }
    } else {
      // 토큰이 없으면 회원가입/로그인 선택 화면으로
      if (mounted) {
        // 인증 체크 완료 후 네이티브 스플래시 제거
        FlutterNativeSplash.remove();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FlutterNativeSplash.preserve()로 네이티브 스플래시가 유지되므로
    // Flutter 레벨에서는 빈 화면으로 두고 인증 체크만 수행
    // 인증 체크 완료 후 FlutterNativeSplash.remove()로 스플래시 제거
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}

