import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';

// 인증번호 검증 서비스
class VerificationService {
  // 인증번호 검증
  Future<bool> verifyCode(
    BuildContext context,
    String phone,
    String code,
    bool isRegister,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return await authProvider.verifyCode(phone, code, isRegister: isRegister);
  }

  // 인증번호 재전송
  Future<bool> resendCode(BuildContext context, String phone) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return await authProvider.resendVerificationCode(phone);
  }
}

