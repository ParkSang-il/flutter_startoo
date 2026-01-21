import 'package:flutter/material.dart';
import 'controllers/verification_code_controller.dart';
import 'widgets/verification_title_section.dart';
import 'widgets/verification_code_input_fields.dart';
import 'widgets/verification_timer_section.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String phone;
  final bool isRegister; // true: 회원가입, false: 로그인

  const VerificationCodeScreen({
    super.key,
    required this.phone,
    required this.isRegister,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  late final VerificationCodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VerificationCodeController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 크기 유지
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // 키보드 외 영역 터치 시 키보드 숨김
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerificationTitleSection(
                  phone: widget.phone,
                  isRegister: widget.isRegister,
                ),
                // 인증번호 입력 필드들
                VerificationCodeInputFields(
                  controller: _controller,
                  phone: widget.phone,
                  isRegister: widget.isRegister,
                  setState: _setState,
                ),
                const SizedBox(height: 32),
                // 타이머 및 재전송 버튼
                VerificationTimerSection(
                  controller: _controller,
                  phone: widget.phone,
                  setState: _setState,
                ),
                if (_controller.isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

