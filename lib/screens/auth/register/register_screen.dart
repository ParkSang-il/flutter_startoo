import 'package:flutter/material.dart';
import 'controllers/register_screen_controller.dart';
import 'widgets/register_title_section.dart';
import 'widgets/register_business_info_fields.dart';
import 'widgets/register_certificate_upload_field.dart';
import 'widgets/register_phone_public_switch.dart';
import 'widgets/register_region_chips.dart';
import 'widgets/register_style_chips.dart';
import 'widgets/register_submit_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterScreenController();
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

  Future<void> _selectAndUploadImage(String type) async {
    await _controller.selectAndUploadImage(context, type, _setState);
  }

  Future<void> _register() async {
    await _controller.register(context, _setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 크기 유지
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  const RegisterTitleSection(),
                  RegisterBusinessInfoFields(controller: _controller),
                  // 사업자등록증
                  RegisterCertificateUploadField(
                    label: '사업자등록증',
                    filePath: _controller.businessCertificatePath,
                    isUploading: _controller.uploadingBusinessCertificate,
                    onSelect: () => _selectAndUploadImage('business_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 자격증
                  RegisterCertificateUploadField(
                    label: '자격증',
                    filePath: _controller.licenseCertificatePath,
                    isUploading: _controller.uploadingLicenseCertificate,
                    onSelect: () => _selectAndUploadImage('license_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 안전교육이수증
                  RegisterCertificateUploadField(
                    label: '안전교육이수증',
                    filePath: _controller.safetyEducationCertificatePath,
                    isUploading: _controller.uploadingSafetyEducationCertificate,
                    onSelect: () => _selectAndUploadImage('safety_education_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 휴대폰번호공개
                  RegisterPhonePublicSwitch(
                    controller: _controller,
                    onChanged: _setState,
                  ),
                  const SizedBox(height: 24),
                  // 작업가능지역
                  RegisterRegionChips(
                    controller: _controller,
                    onChanged: _setState,
                  ),
                  const SizedBox(height: 24),
                  // 작업가능한스타일
                  RegisterStyleChips(
                    controller: _controller,
                    onChanged: _setState,
                  ),
                  const SizedBox(height: 32),
                  // 사업자 정보 등록 완료 버튼
                  RegisterSubmitButton(
                    controller: _controller,
                    onPressed: _register,
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

