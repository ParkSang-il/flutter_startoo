import 'package:flutter/material.dart';
import '../services/certificate_upload_service.dart';
import '../services/business_registration_service.dart';

// RegisterScreen 컨트롤러
class RegisterScreenController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final CertificateUploadService _certificateUploadService = CertificateUploadService();
  final BusinessRegistrationService _businessRegistrationService = BusinessRegistrationService();

  // 사업자 추가 정보 필드
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController addressDetailController = TextEditingController();

  // 파일 경로 (업로드된 파일 경로)
  String? businessCertificatePath;
  String? licenseCertificatePath;
  String? safetyEducationCertificatePath;

  // 업로드 중 상태
  bool uploadingBusinessCertificate = false;
  bool uploadingLicenseCertificate = false;
  bool uploadingSafetyEducationCertificate = false;

  // 스위치 및 선택 필드
  bool contactPhonePublic = true;
  List<String> availableRegions = [];
  List<String> mainStyles = [];

  bool isLoading = false;

  // 이미지 선택 및 업로드
  Future<void> selectAndUploadImage(
    BuildContext context,
    String type,
    VoidCallback setState,
  ) async {
    setState();
    switch (type) {
      case 'business_certificate':
        uploadingBusinessCertificate = true;
        break;
      case 'license_certificate':
        uploadingLicenseCertificate = true;
        break;
      case 'safety_education_certificate':
        uploadingSafetyEducationCertificate = true;
        break;
    }
    setState();

    final uploadedPath = await _certificateUploadService.selectAndUploadImage(context, type);

    if (context.mounted) {
      setState();
      switch (type) {
        case 'business_certificate':
          businessCertificatePath = uploadedPath;
          uploadingBusinessCertificate = false;
          break;
        case 'license_certificate':
          licenseCertificatePath = uploadedPath;
          uploadingLicenseCertificate = false;
          break;
        case 'safety_education_certificate':
          safetyEducationCertificatePath = uploadedPath;
          uploadingSafetyEducationCertificate = false;
          break;
      }
      setState();
    }
  }

  // 사업자 정보 등록
  Future<void> register(BuildContext context, VoidCallback setState) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading = true;
    setState();

    final success = await _businessRegistrationService.registerBusinessInfo(
      context,
      businessNameController.text.trim(),
      businessNumberController.text.trim(),
      businessCertificatePath,
      licenseCertificatePath,
      safetyEducationCertificatePath,
      addressController.text.trim(),
      addressDetailController.text.trim(),
      contactPhonePublic,
      availableRegions,
      mainStyles,
    );

    if (context.mounted) {
      isLoading = false;
      setState();
    }
  }

  // 리소스 정리
  void dispose() {
    businessNameController.dispose();
    businessNumberController.dispose();
    addressController.dispose();
    addressDetailController.dispose();
  }
}

