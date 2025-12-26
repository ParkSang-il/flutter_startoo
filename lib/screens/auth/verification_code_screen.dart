import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'user_type_selection_screen.dart';

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
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _remainingSeconds = 180; // 3분
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // 첫 번째 입력 필드에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResend = true;
          }
        });
        return _remainingSeconds > 0;
      }
      return false;
    });
  }

  void _onCodeChanged(int index, String value) {

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // 6자리 모두 입력되었는지 확인
    final code = _controllers.map((c) => c.text).join();

    // 응답 데이터 확인 및 로그
    debugPrint('=== 인증번호 6자리 ===');
    debugPrint('Code: ${code}');

    if (code.length == 6) {
      _verifyCode(code);
    }
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyCode(widget.phone, code);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // 로그인 플로우인 경우
      if (!widget.isRegister) {
        // 기존 사용자인 경우 홈으로 이동
        if (authProvider.currentUser != null) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          // 신규 사용자인 경우 에러 (이미 가입된 번호가 아님)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가입되지 않은 번호입니다. 회원가입을 진행해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
          // 입력 필드 초기화
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      } else {
        // 회원가입 플로우인 경우
        if (authProvider.currentUser != null) {
          // 기존 사용자인 경우 에러 (이미 가입된 번호)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 가입된 번호입니다. 로그인을 진행해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
          // 입력 필드 초기화
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        } else {
          // 신규 사용자인 경우 회원 타입 선택 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserTypeSelectionScreen(phone: widget.phone),
            ),
          );
        }
      }
    } else {
      // 에러 메시지 확인
      final errorMessage = authProvider.errorMessage ?? '인증번호가 올바르지 않습니다.';
      
      // "인증번호를 찾을 수 없습니다" 메시지인 경우 타이머 제거 및 재전송 버튼 표시
      if (errorMessage.contains('인증번호를 찾을 수 없습니다') || 
          errorMessage.contains('인증번호를 다시 발송해주세요')) {
        setState(() {
          _remainingSeconds = 0;
          _canResend = true;
        });
      }
      
      // 에러 메시지 표시 및 입력 필드 초기화
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      // 입력 필드 초기화
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _canResend = false;
      _remainingSeconds = 180;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationCode(widget.phone);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호가 재전송되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      // 입력 필드 초기화
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } else {
      setState(() {
        _canResend = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '인증번호 재전송에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '뒤로',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 타이틀
              Text(
                widget.isRegister
                    ? '회원가입을 위해\n인증번호를 입력해주세요'
                    : '로그인을 위해\n인증번호를 입력해주세요',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.phone.substring(0, 3)}-${widget.phone.substring(3, 7)}-${widget.phone.substring(7)}로\n인증번호를 발송했습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),
              // 인증번호 입력 필드들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: false,
                      ),
                      onChanged: (value) => _onCodeChanged(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // 타이머 및 재전송 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend && _remainingSeconds > 0)
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (_canResend || _remainingSeconds == 0) ...[
                    TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      child: Text(
                        '인증번호 재전송',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

