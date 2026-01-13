import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/snackbar_helper.dart';
import 'verification_code_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isPhoneValid = false;  // 휴대폰 번호 유효성 상태

  @override
  void initState() {
    super.initState();
    // 입력값 변경 감지
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhone);
    _phoneController.dispose();
    super.dispose();
  }

  // 휴대폰 번호 유효성 검사
  void _validatePhone() {
    final value = _phoneController.text;
    if (value.isEmpty) {
      setState(() {
        _isPhoneValid = false;
      });
      return;
    }

    final digits = PhoneFormatter.extractDigits(value);
    final isValid = PhoneFormatter.isValid(digits);

    setState(() {
      _isPhoneValid = isValid;
    });
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phone = PhoneFormatter.extractDigits(_phoneController.text);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.sendVerificationCode(phone);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // 인증번호 입력 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationCodeScreen(
            phone: phone,
            isRegister: widget.isRegister,
          ),
        ),
      );
    } else {
      // 에러 메시지 표시
      SnackBarHelper.showError(
        context,
        authProvider.errorMessage ?? '인증번호 발송에 실패했습니다.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // 타이틀
                Text(
                  widget.isRegister
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
                // 전화번호 입력 필드
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _PhoneInputFormatter(),
                  ],
                  cursorColor: Theme.of(context).colorScheme.onPrimary,
                  decoration: InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: '010-1234-5678',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onPrimary,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '휴대폰 번호를 입력해주세요';
                    }
                    final digits = PhoneFormatter.extractDigits(value);
                    if (!PhoneFormatter.isValid(digits)) {
                      return '올바른 휴대폰 번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // 인증번호 받기 버튼
                TextButton(
                  onPressed: (_isLoading || !_isPhoneValid) ? null : _sendVerificationCode,
                  style: TextButton.styleFrom(
                    backgroundColor: _isPhoneValid && !_isLoading
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade800,  // 비활성화 시 어두운 색상
                    foregroundColor: _isPhoneValid && !_isLoading
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.grey.shade600,  // 비활성화 시 어두운 텍스트 색상
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade800,  // 비활성화 배경색
                    disabledForegroundColor: Colors.grey.shade600,  // 비활성화 텍스트 색상
                  ),
                  child: _isLoading
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
                          blurRadius: 1,              // 그림자의 퍼짐 정도
                          color: Colors.black87, // 그림자 색상
                          offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
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
            ),
          ),
        ),
      ),
    );
  }
}

// 전화번호 자동 포맷팅
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final formatted = PhoneFormatter.format(text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

