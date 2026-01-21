import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../services/ncp_storage_service.dart';
import '../../../../utils/snackbar_helper.dart';

// 증명서 업로드 서비스
class CertificateUploadService {
  final NcpStorageService _storageService = NcpStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // 이미지 선택 및 업로드
  Future<String?> selectAndUploadImage(
    BuildContext context,
    String type,
  ) async {
    try {
      // 이미지 선택
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 이미지 품질 (0-100)
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final fileName = path.basename(pickedFile.path);

      // NCP Storage에 업로드
      final uploadedPath = await _storageService.uploadImage(file, fileName);

      if (uploadedPath != null) {
        if (context.mounted) {
          SnackBarHelper.showSuccess(context, '파일이 업로드되었습니다.');
        }
        return uploadedPath;
      } else {
        if (context.mounted) {
          SnackBarHelper.showError(context, '파일 업로드에 실패했습니다.');
        }
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          '파일 선택 중 오류가 발생했습니다: ${e.toString()}',
        );
      }
      return null;
    }
  }
}

