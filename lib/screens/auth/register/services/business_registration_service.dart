import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/snackbar_helper.dart';

// 사업자 정보 등록 서비스
class BusinessRegistrationService {
  // 사업자 정보 등록
  Future<bool> registerBusinessInfo(
    BuildContext context,
    String businessName,
    String businessNumber,
    String? businessCertificate,
    String? licenseCertificate,
    String? safetyEducationCertificate,
    String address,
    String? addressDetail,
    bool contactPhonePublic,
    List<String> availableRegions,
    List<String> mainStyles,
  ) async {
    // 필수 파일 업로드 확인
    if (businessCertificate == null) {
      SnackBarHelper.showError(context, '사업자등록증을 업로드해주세요.');
      return false;
    }
    if (licenseCertificate == null) {
      SnackBarHelper.showError(context, '자격증 이미지를 업로드해주세요.');
      return false;
    }
    if (safetyEducationCertificate == null) {
      SnackBarHelper.showError(context, '안전교육이수증을 업로드해주세요.');
      return false;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.registerBusinessInfo(
      businessName: businessName,
      businessNumber: businessNumber,
      businessCertificate: businessCertificate,
      licenseCertificate: licenseCertificate,
      safetyEducationCertificate: safetyEducationCertificate,
      address: address,
      addressDetail: addressDetail,
      contactPhonePublic: contactPhonePublic,
      availableRegions: availableRegions,
      mainStyles: mainStyles,
    );

    if (!context.mounted) return false;

    if (result['success'] == true) {
      // 사업자 추가정보 입력 완료 후 피드리스트로 이동
      SnackBarHelper.showSuccess(
        context,
        result['message'] ?? '사업자 정보가 등록되었습니다.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      return true;
    } else {
      SnackBarHelper.showError(
        context,
        result['message'] ?? '사업자 정보 등록에 실패했습니다.',
      );
      return false;
    }
  }
}

