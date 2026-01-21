import 'package:flutter/material.dart';

class PhoneInputTitleSection extends StatelessWidget {
  final bool isRegister;

  const PhoneInputTitleSection({
    super.key,
    required this.isRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // 타이틀
        Text(
          isRegister
              ? '회원가입을 위해\n휴대폰 번호를 입력해주세요'
              : '로그인을 위해\n휴대폰 번호를 입력해주세요',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '인증번호를 발송해드립니다',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

