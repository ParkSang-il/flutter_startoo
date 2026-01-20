import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/ncp_storage_service.dart';
import 'package:path/path.dart' as path;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 사업자 추가 정보 필드
  final _businessNameController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();
  
  // 파일 경로 (업로드된 파일 경로)
  String? _businessCertificatePath;
  String? _licenseCertificatePath;
  String? _safetyEducationCertificatePath;
  
  // 선택된 파일 (임시)
  File? _selectedBusinessCertificate;
  File? _selectedLicenseCertificate;
  File? _selectedSafetyEducationCertificate;
  
  
  // 업로드 중 상태
  bool _uploadingBusinessCertificate = false;
  bool _uploadingLicenseCertificate = false;
  bool _uploadingSafetyEducationCertificate = false;
  
  final NcpStorageService _storageService = NcpStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // 스위치 및 선택 필드
  bool _contactPhonePublic = true;
  List<String> _availableRegions = [];
  List<String> _mainStyles = [];
  
  bool _isLoading = false;

  // 작업가능지역 옵션
  final List<String> _regionOptions = ['전주', '남원', '군산', '익산', '정읍', '김제', '완주', '진안', '무주', '장수', '임실', '순창', '고창', '부안'];
  
  // 작업가능한스타일 옵션
  final List<String> _styleOptions = ['이레즈미', '워터칼라', '트라이벌', '올드스쿨', '뉴스쿨', '리얼리스틱', '미니멀', '블랙워크', '컬러', '라인워크'];

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessNumberController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 필수 파일 업로드 확인
    if (_businessCertificatePath == null) {
      SnackBarHelper.showError(context, '사업자등록증을 업로드해주세요.');
      return;
    }
    if (_licenseCertificatePath == null) {
      SnackBarHelper.showError(context, '자격증 이미지를 업로드해주세요.');
      return;
    }
    if (_safetyEducationCertificatePath == null) {
      SnackBarHelper.showError(context, '안전교육이수증을 업로드해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.registerBusinessInfo(
      businessName: _businessNameController.text.trim(),
      businessNumber: _businessNumberController.text.trim(),
      businessCertificate: _businessCertificatePath,
      licenseCertificate: _licenseCertificatePath,
      safetyEducationCertificate: _safetyEducationCertificatePath,
      address: _addressController.text.trim(),
      addressDetail: _addressDetailController.text.trim(),
      contactPhonePublic: _contactPhonePublic,
      availableRegions: _availableRegions,
      mainStyles: _mainStyles,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      // 사업자 추가정보 입력 완료 후 피드리스트로 이동
      SnackBarHelper.showSuccess(context, result['message'] ?? '사업자 정보가 등록되었습니다.');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      SnackBarHelper.showError(
        context,
        result['message'] ?? '사업자 정보 등록에 실패했습니다.',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // 타이틀
                Text(
                  '사업자 정보를\n입력해주세요',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '사업자 인증을 위해 추가 정보가 필요합니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                // 사업자 추가 정보 필드
                  const SizedBox(height: 32),
                  // 상호
                  TextFormField(
                    controller: _businessNameController,
                    cursorColor: Theme.of(context).colorScheme.onPrimary,
                    decoration: _buildInputDecoration('상호', '상호명을 입력하세요'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '상호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // 사업자등록번호
                  TextFormField(
                    cursorColor: Theme.of(context).colorScheme.onPrimary,
                    controller: _businessNumberController,
                    decoration: _buildInputDecoration('사업자등록번호', '123-45-67890'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '사업자등록번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // 사업자등록증
                  _buildFileUploadField(
                    context,
                    '사업자등록증',
                    _businessCertificatePath,
                    _uploadingBusinessCertificate,
                    () => _selectAndUploadImage('business_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 자격증
                  _buildFileUploadField(
                    context,
                    '자격증',
                    _licenseCertificatePath,
                    _uploadingLicenseCertificate,
                    () => _selectAndUploadImage('license_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 안전교육이수증
                  _buildFileUploadField(
                    context,
                    '안전교육이수증',
                    _safetyEducationCertificatePath,
                    _uploadingSafetyEducationCertificate,
                    () => _selectAndUploadImage('safety_education_certificate'),
                  ),
                  const SizedBox(height: 24),
                  // 주소
                  TextFormField(
                    controller: _addressController,
                    cursorColor: Theme.of(context).colorScheme.onPrimary,
                    decoration: _buildInputDecoration('주소', '전북특별자치도 전주시 덕진구 백제대로 567'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '주소를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // 상세주소
                  TextFormField(
                    controller: _addressDetailController,
                    cursorColor: Theme.of(context).colorScheme.onPrimary,
                    decoration: _buildInputDecoration('상세주소 (선택)', '4층 401호'),
                  ),
                  const SizedBox(height: 24),
                  // 휴대폰번호공개
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '휴대폰번호공개',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Switch(
                        value: _contactPhonePublic,
                        onChanged: (value) => setState(() => _contactPhonePublic = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 작업가능지역
                  Text(
                    '작업가능지역',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regionOptions.map((region) {
                      final isSelected = _availableRegions.contains(region);
                      return FilterChip(
                        label: Text(region),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.background,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, shadows: [
                          Shadow(
                            blurRadius: 1,              // 그림자의 퍼짐 정도
                            color: Colors.black87, // 그림자 색상
                            offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
                          ),
                        ]),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _availableRegions.add(region);
                            } else {
                              _availableRegions.remove(region);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // 작업가능한스타일
                  Text(
                    '작업가능한스타일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _styleOptions.map((style) {
                      final isSelected = _mainStyles.contains(style);
                      return FilterChip(
                        label: Text(style),
                        selected: isSelected,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, shadows: [
                          Shadow(
                            blurRadius: 1,              // 그림자의 퍼짐 정도
                            color: Colors.black87, // 그림자 색상
                            offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
                          ),
                        ]),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _mainStyles.add(style);
                            } else {
                              _mainStyles.remove(style);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                // 사업자 정보 등록 완료 버튼
                TextButton(
                  onPressed: _isLoading ? null : _register,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                          '등록 완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
    );
  }

  // 이미지 선택 및 업로드
  Future<void> _selectAndUploadImage(String type) async {
    try {
      // 이미지 선택
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 이미지 품질 (0-100)
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileName = path.basename(pickedFile.path);

      // 업로드 상태 설정
      setState(() {
        switch (type) {
          case 'business_certificate':
            _uploadingBusinessCertificate = true;
            _selectedBusinessCertificate = file;
            break;
          case 'license_certificate':
            _uploadingLicenseCertificate = true;
            _selectedLicenseCertificate = file;
            break;
          case 'safety_education_certificate':
            _uploadingSafetyEducationCertificate = true;
            _selectedSafetyEducationCertificate = file;
            break;
        }
      });

      // NCP Storage에 업로드
      final uploadedPath = await _storageService.uploadImage(file, fileName);

      if (uploadedPath != null) {
        setState(() {
          switch (type) {
            case 'business_certificate':
              _businessCertificatePath = uploadedPath;
              _uploadingBusinessCertificate = false;
              break;
            case 'license_certificate':
              _licenseCertificatePath = uploadedPath;
              _uploadingLicenseCertificate = false;
              break;
            case 'safety_education_certificate':
              _safetyEducationCertificatePath = uploadedPath;
              _uploadingSafetyEducationCertificate = false;
              break;
          }
        });

        if (mounted) {
          SnackBarHelper.showSuccess(context, '파일이 업로드되었습니다.');
        }
      } else {
        setState(() {
          switch (type) {
            case 'business_certificate':
              _uploadingBusinessCertificate = false;
              _selectedBusinessCertificate = null;
              break;
            case 'license_certificate':
              _uploadingLicenseCertificate = false;
              _selectedLicenseCertificate = null;
              break;
            case 'safety_education_certificate':
              _uploadingSafetyEducationCertificate = false;
              _selectedSafetyEducationCertificate = null;
              break;
          }
        });

        if (mounted) {
          SnackBarHelper.showError(context, '파일 업로드에 실패했습니다.');
        }
      }
    } catch (e) {
      setState(() {
        switch (type) {
          case 'business_certificate':
            _uploadingBusinessCertificate = false;
            _selectedBusinessCertificate = null;
            break;
          case 'license_certificate':
            _uploadingLicenseCertificate = false;
            _selectedLicenseCertificate = null;
            break;
          case 'safety_education_certificate':
            _uploadingSafetyEducationCertificate = false;
            _selectedSafetyEducationCertificate = null;
            break;
        }
      });

      if (mounted) {
        SnackBarHelper.showError(context, '파일 선택 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  Widget _buildFileUploadField(
    BuildContext context,
    String label,
    String? filePath,
    bool isUploading,
    VoidCallback onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onSelect,
          icon: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FaIcon(FontAwesomeIcons.fileArrowUp, color: Theme.of(context).colorScheme.onPrimary),
          label: Text(
            isUploading
                ? '업로드 중...'
                : (filePath != null ? '파일 선택됨' : '파일 선택'),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, shadows: [
              Shadow(
                blurRadius: 1,              // 그림자의 퍼짐 정도
                color: Colors.black87, // 그림자 색상
                offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
              ),
            ]),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: filePath != null ? Theme.of(context).colorScheme.primary : Theme.of(context).scaffoldBackgroundColor
          ),
        ),
      ],
    );
  }
}

