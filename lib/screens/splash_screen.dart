import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:starttoo/screens/feed/feed_list/feed_list_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/api_client.dart';
import 'auth/login_or_register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool _isChecking = false; // 중복 실행 방지 플래그
  bool _hasNavigated = false; // 네비게이션 완료 플래그

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 백그라운드에서 포그라운드로 돌아올 때는 스플래시 화면을 건너뛰고
    // 이미 인증된 상태라면 피드 화면으로 바로 이동
    if (state == AppLifecycleState.resumed && mounted && !_hasNavigated) {
      // 이미 네비게이션이 완료되었거나 체크 중이면 무시
      if (!_isChecking) {
        _checkAuth();
      }
    }
  }

  Future<void> _checkAuth() async {
    // 이미 체크 중이거나 네비게이션이 완료되었으면 무시
    if (_isChecking || _hasNavigated || !mounted) return;
    
    _isChecking = true;

    try {
      // 네이티브 스플래시가 표시되는 동안 인증 체크 수행
      final apiClient = ApiClient();
      final hasToken = await apiClient.hasToken();

      if (!mounted || _hasNavigated) {
        _isChecking = false;
        return;
      }

      // 토큰이 있으면 사용자 정보 가져오기 시도 (리프레시 포함)
      if (hasToken) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.getMe();

        if (!mounted || _hasNavigated) {
          _isChecking = false;
          return;
        }

        if (success && authProvider.isAuthenticated) {
          // 인증 체크 완료 후 네이티브 스플래시 제거
          FlutterNativeSplash.remove();
          _hasNavigated = true;
          // 사용자 정보를 성공적으로 가져왔으면 홈으로 이동
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const FeedListPage()),
            );
          }
        } else {
          // 토큰이 유효하지 않고 리프레시도 실패한 경우 로그인 화면으로
          // 토큰 삭제
          await apiClient.clearTokens();
          // 인증 체크 완료 후 네이티브 스플래시 제거
          FlutterNativeSplash.remove();
          _hasNavigated = true;
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
            );
          }
        }
      } else {
        // 토큰이 없으면 회원가입/로그인 선택 화면으로
        if (mounted && !_hasNavigated) {
          // 인증 체크 완료 후 네이티브 스플래시 제거
          FlutterNativeSplash.remove();
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
          );
        }
      }
    } catch (e) {
      // 에러 발생 시에도 스플래시 제거하고 로그인 화면으로
      if (mounted && !_hasNavigated) {
        FlutterNativeSplash.remove();
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
        );
      }
    } finally {
      _isChecking = false;
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

