import 'package:flutter/material.dart';
import '../phone_input/phone_input_screen.dart';
import 'controllers/terms_agreement_controller.dart';
import 'widgets/terms_title_section.dart';
import 'widgets/terms_agree_all_checkbox.dart';
import 'widgets/terms_agreement_item.dart';
import 'widgets/terms_detail_modal.dart';
import 'widgets/terms_submit_button.dart';
import 'model/terms_content.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  late final TermsAgreementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TermsAgreementController();
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onNext() {
    if (!_controller.canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 약관 동의 완료 후 휴대폰 입력 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhoneInputScreen(isRegister: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TermsTitleSection(),
                    // 전체 동의
                    TermsAgreeAllCheckbox(
                      controller: _controller,
                      onChanged: _setState,
                    ),
                    const SizedBox(height: 24),
                    // 이용약관 (필수)
                    TermsAgreementItem(
                      title: '이용약관',
                      isRequired: true,
                      isAgreed: _controller.agreeTerms,
                      onChanged: (value) {
                        _controller.onAgreeTermsChanged(value, _setState);
                      },
                      onViewDetail: () {
                        TermsDetailModal.show(
                          context,
                          '이용약관',
                          TermsContent.getTermsContent(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // 개인정보 처리방침 (필수)
                    TermsAgreementItem(
                      title: '개인정보 처리방침',
                      isRequired: true,
                      isAgreed: _controller.agreePrivacy,
                      onChanged: (value) {
                        _controller.onAgreePrivacyChanged(value, _setState);
                      },
                      onViewDetail: () {
                        TermsDetailModal.show(
                          context,
                          '개인정보 처리방침',
                          TermsContent.getPrivacyContent(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // 마케팅 정보 수신 (선택)
                    TermsAgreementItem(
                      title: '마케팅 정보 수신',
                      isRequired: false,
                      isAgreed: _controller.agreeMarketing,
                      onChanged: (value) {
                        _controller.onAgreeMarketingChanged(value, _setState);
                      },
                      onViewDetail: () {
                        TermsDetailModal.show(
                          context,
                          '마케팅 정보 수신',
                          TermsContent.getMarketingContent(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // 하단 고정 버튼 영역
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 25),
              child: SafeArea(
                top: false,
                child: TermsSubmitButton(
                  controller: _controller,
                  onPressed: _onNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

