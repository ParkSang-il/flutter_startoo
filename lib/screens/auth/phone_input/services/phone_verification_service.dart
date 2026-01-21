import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/snackbar_helper.dart';
import '../../verification_code/verification_code_screen.dart';

// 전화번호 인증 서비스
class PhoneVerificationService {
  // 인증번호 발송
  Future<bool> sendVerificationCode(
    BuildContext context,
    String phone,
    bool isRegister,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendVerificationCode(phone);

    if (!context.mounted) return false;

    if (success) {
      // 인증번호 입력 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationCodeScreen(
            phone: phone,
            isRegister: isRegister,
          ),
        ),
      );
      return true;
    } else {
      // 에러 메시지 표시
      SnackBarHelper.showError(
        context,
        authProvider.errorMessage ?? '인증번호 발송에 실패했습니다.',
      );
      return false;
    }
  }
}

