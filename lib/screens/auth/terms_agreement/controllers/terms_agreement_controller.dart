import 'package:flutter/material.dart';

// TermsAgreementScreen 컨트롤러
class TermsAgreementController {
  bool agreeAll = false;
  bool agreeTerms = false; // 이용약관 (필수)
  bool agreePrivacy = false; // 개인정보 처리방침 (필수)
  bool agreeMarketing = false; // 마케팅 정보 수신 (선택)

  void onAgreeAllChanged(bool? value, VoidCallback setState) {
    if (value == null) return;
    agreeAll = value;
    agreeTerms = value;
    agreePrivacy = value;
    agreeMarketing = value;
    setState();
  }

  void onAgreeTermsChanged(bool? value, VoidCallback setState) {
    if (value == null) return;
    agreeTerms = value;
    updateAgreeAll(setState);
  }

  void onAgreePrivacyChanged(bool? value, VoidCallback setState) {
    if (value == null) return;
    agreePrivacy = value;
    updateAgreeAll(setState);
  }

  void onAgreeMarketingChanged(bool? value, VoidCallback setState) {
    if (value == null) return;
    agreeMarketing = value;
    updateAgreeAll(setState);
  }

  void updateAgreeAll(VoidCallback setState) {
    agreeAll = agreeTerms && agreePrivacy && agreeMarketing;
    setState();
  }

  bool get canProceed => agreeTerms && agreePrivacy;
}

