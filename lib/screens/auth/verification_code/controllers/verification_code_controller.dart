import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/snackbar_helper.dart';
import '../../user_type_selection_screen.dart';
import '../services/verification_service.dart';
import '../services/timer_service.dart';

// VerificationCodeScreen 컨트롤러
class VerificationCodeController {
  final List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final VerificationService _verificationService = VerificationService();
  final TimerService _timerService = TimerService();

  bool isLoading = false;
  int remainingSeconds = 180; // 3분
  bool canResend = false;

  void initialize() {
    _timerService.startTimer(
      onTick: (seconds) {
        remainingSeconds = seconds;
        canResend = seconds == 0;
      },
    );
    // 첫 번째 입력 필드에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNodes[0].requestFocus();
    });
  }

  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    _timerService.dispose();
  }

  void onCodeChanged(
    int index,
    String value,
    String phone,
    bool isRegister,
    BuildContext context,
    VoidCallback setState,
  ) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // 6자리 모두 입력되었는지 확인
    final code = controllers.map((c) => c.text).join();

    debugPrint('=== 인증번호 6자리 ===');
    debugPrint('Code: $code');

    if (code.length == 6) {
      verifyCode(code, phone, isRegister, context, setState);
    }
  }

  Future<void> verifyCode(
    String code,
    String phone,
    bool isRegister,
    BuildContext context,
    VoidCallback setState,
  ) async {
    isLoading = true;
    setState();

    final success = await _verificationService.verifyCode(
      context,
      phone,
      code,
      isRegister,
    );

    isLoading = false;
    setState();

    if (!context.mounted) return;

    if (success) {
      // 로그인 플로우인 경우
      if (!isRegister) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser != null) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        // 회원가입 플로우인 경우 - 바로 회원가입 API 호출 (일반회원으로)
        await _registerAfterVerification(context, phone, setState);
      }
    } else {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final errorMessage = authProvider.errorMessage ?? '인증번호가 올바르지 않습니다.';

      // "인증번호를 찾을 수 없습니다" 메시지인 경우 타이머 제거 및 재전송 버튼 표시
      if (errorMessage.contains('인증번호를 찾을 수 없습니다') ||
          errorMessage.contains('인증번호를 다시 발송해주세요')) {
        remainingSeconds = 0;
        canResend = true;
        setState();
      }

      // 에러 메시지 표시
      SnackBarHelper.showError(context, errorMessage);

      // 회원가입 플로우에서 "이미 가입된 번호입니다" 에러인 경우 맨 처음 화면으로 이동
      if (isRegister && errorMessage.contains('이미 가입된 번호입니다')) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      // 입력 필드 초기화
      for (var controller in controllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
    }
  }

  Future<void> resendCode(
    String phone,
    BuildContext context,
    VoidCallback setState,
  ) async {
    isLoading = true;
    canResend = false;
    remainingSeconds = 180;
    setState();

    final success = await _verificationService.resendCode(context, phone);

    isLoading = false;
    setState();

    if (!context.mounted) return;

    if (success) {
      _timerService.startTimer(
        onTick: (seconds) {
          remainingSeconds = seconds;
          canResend = seconds == 0;
          setState();
        },
      );
      SnackBarHelper.showSuccess(context, '인증번호가 재전송되었습니다.');
      // 입력 필드 초기화
      for (var controller in controllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
    } else {
      canResend = true;
      setState();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      SnackBarHelper.showError(
        context,
        authProvider.errorMessage ?? '인증번호 재전송에 실패했습니다.',
      );
    }
  }

  // 회원가입 인증 후 바로 회원가입 처리
  Future<void> _registerAfterVerification(
    BuildContext context,
    String phone,
    VoidCallback setState,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 일반회원으로 바로 회원가입 API 호출
    final success = await authProvider.register(
      phone: phone,
      userType: 1, // 일반 회원
      nickname: null, // 닉네임 없이
    );

    if (!context.mounted) return;

    // 로딩 닫기
    Navigator.of(context).pop();

    if (success) {
      // 회원가입 성공 - 사업자 여부 확인 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const UserTypeSelectionScreen(),
        ),
      );
    } else {
      // 회원가입 실패 - 에러 메시지 표시
      SnackBarHelper.showError(
        context,
        authProvider.errorMessage ?? '회원가입에 실패했습니다.',
      );
    }
  }
}

