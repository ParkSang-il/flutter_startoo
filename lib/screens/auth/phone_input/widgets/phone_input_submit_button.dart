import 'package:flutter/material.dart';
import '../controllers/phone_input_controller.dart';

class PhoneInputSubmitButton extends StatelessWidget {
  final PhoneInputController controller;
  final VoidCallback onPressed;

  const PhoneInputSubmitButton({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: (controller.isLoading || !controller.isPhoneValid)
              ? null
              : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: controller.isPhoneValid && !controller.isLoading
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade800, // 비활성화 시 어두운 색상
            foregroundColor: controller.isPhoneValid && !controller.isLoading
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.grey.shade600, // 비활성화 시 어두운 텍스트 색상
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey.shade800, // 비활성화 배경색
            disabledForegroundColor: Colors.grey.shade600, // 비활성화 텍스트 색상
          ),
          child: controller.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )
              : const Text(
                  '인증번호 받기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        blurRadius: 1,
                        color: Colors.black87,
                        offset: Offset(0.3, 0.3),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        // 안내 문구
        Text(
          '인증번호는 3분간 유효합니다',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

