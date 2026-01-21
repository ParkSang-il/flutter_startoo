import 'package:flutter/material.dart';
import '../../../../utils/phone_formatter.dart';
import '../services/phone_verification_service.dart';

// PhoneInputScreen 컨트롤러
class PhoneInputController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final PhoneVerificationService _verificationService = PhoneVerificationService();

  bool isLoading = false;
  bool isPhoneValid = false; // 휴대폰 번호 유효성 상태

  void initialize(VoidCallback setState) {
    // 입력값 변경 감지
    phoneController.addListener(() => validatePhone(setState));
  }

  void dispose() {
    phoneController.removeListener(() {});
    phoneController.dispose();
  }

  // 휴대폰 번호 유효성 검사
  void validatePhone(VoidCallback setState) {
    final value = phoneController.text;
    if (value.isEmpty) {
      isPhoneValid = false;
      setState();
      return;
    }

    final digits = PhoneFormatter.extractDigits(value);
    final isValid = PhoneFormatter.isValid(digits);

    isPhoneValid = isValid;
    setState();
  }

  // 인증번호 발송
  Future<bool> sendVerificationCode(
    BuildContext context,
    bool isRegister,
    VoidCallback setState,
  ) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    isLoading = true;
    setState();

    final phone = PhoneFormatter.extractDigits(phoneController.text);
    final success = await _verificationService.sendVerificationCode(
      context,
      phone,
      isRegister,
    );

    isLoading = false;
    setState();

    return success;
  }
}

