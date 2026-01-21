import 'package:flutter/material.dart';
import 'controllers/phone_input_controller.dart';
import 'widgets/phone_input_title_section.dart';
import 'widgets/phone_input_field.dart';
import 'widgets/phone_input_submit_button.dart';

class PhoneInputScreen extends StatefulWidget {
  final bool isRegister; // true: 회원가입, false: 로그인

  const PhoneInputScreen({
    super.key,
    required this.isRegister,
  });

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  late final PhoneInputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhoneInputController();
    _controller.initialize(_setState);
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

  Future<void> _sendVerificationCode() async {
    await _controller.sendVerificationCode(context, widget.isRegister, _setState);
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
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhoneInputTitleSection(isRegister: widget.isRegister),
                  // 전화번호 입력 필드
                  PhoneInputField(
                    controller: _controller,
                    onChanged: _setState,
                  ),
                  const SizedBox(height: 32),
                  // 인증번호 받기 버튼
                  PhoneInputSubmitButton(
                    controller: _controller,
                    onPressed: _sendVerificationCode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

