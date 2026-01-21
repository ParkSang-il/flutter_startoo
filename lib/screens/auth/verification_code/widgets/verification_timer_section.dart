import 'package:flutter/material.dart';
import '../controllers/verification_code_controller.dart';

class VerificationTimerSection extends StatelessWidget {
  final VerificationCodeController controller;
  final String phone;
  final VoidCallback setState;

  const VerificationTimerSection({
    super.key,
    required this.controller,
    required this.phone,
    required this.setState,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!controller.canResend && controller.remainingSeconds > 0)
          Text(
            _formatTime(controller.remainingSeconds),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        if (controller.canResend || controller.remainingSeconds == 0) ...[
          TextButton(
            onPressed: controller.isLoading
                ? null
                : () => controller.resendCode(phone, context, setState),
            child: Text(
              '인증번호 재전송',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

