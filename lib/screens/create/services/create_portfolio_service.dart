import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../services/auth_service.dart';
import '../../../services/ncp_storage_service.dart';
import '../../../utils/snackbar_helper.dart';
import '../model/media_item.dart';
import 'tag_extractor_service.dart';

// 포트폴리오 생성 서비스
class CreatePortfolioService {
  final AuthService _authService = AuthService();
  final NcpStorageService _storageService = NcpStorageService();

  // 게시글 등록
  Future<bool> submitPost(
    BuildContext context,
    List<MediaItem> mediaItems,
    String content,
  ) async {
    if (mediaItems.isEmpty) {
      SnackBarHelper.showError(context, '이미지 또는 비디오를 최소 1개 이상 선택해주세요.');
      return false;
    }

    // 텍스트에서 태그 리스트 추출
    final List<String> extractedTags = TagExtractorService.extractTags(content);

    try {
      // 1. 파일 경로만 미리 생성 (업로드하지 않음)
      List<Map<String, dynamic>> imagePaths = [];
      List<Map<String, dynamic>> videoPaths = [];
      List<Map<String, dynamic>> mediaFiles = []; // 실제 파일과 경로 정보 저장
      int videoOrder = 0;
      int imageOrder = 0;
      bool hasVideoBefore = false; // 이미지 앞에 비디오가 있는지 확인

      for (var mediaItem in mediaItems) {
        if (mediaItem.isVideo) {
          // 비디오 파일 경로 생성 (업로드하지 않음)
          final originalFileName = path.basename(mediaItem.file.path);
          final extension = path.extension(originalFileName).toLowerCase();
          // mov 파일은 mp4로 변환하여 저장
          final fileName = extension == '.mov' 
              ? '${path.basenameWithoutExtension(originalFileName)}.mp4'
              : originalFileName;
          final filePath = _storageService.generateVideoPath(fileName);

          videoPaths.add({
            'video_file_path': filePath,
            'video_order': videoOrder,
          });
          mediaFiles.add({
            'type': 'video',
            'file': mediaItem.file,
            'fileName': fileName,
            'path': filePath,
          });
          videoOrder++;
          hasVideoBefore = true;
        } else {
          // 이미지 파일 경로 생성 (업로드하지 않음)
          final fileName = path.basename(mediaItem.file.path);
          // 각 이미지마다 고유한 파일명 생성 (imageOrder를 인덱스로 사용)
          final filePath = _storageService.generateImagePath(fileName, index: imageOrder);

          // 비디오가 먼저 있으면 image_order는 1부터 시작
          final currentImageOrder = hasVideoBefore ? imageOrder + 1 : imageOrder;
          
          imagePaths.add({
            'image_url': filePath, // 상대 경로만 전송
            'image_order': currentImageOrder,
            'scale': 1.0,
            'offset_x': 0.0,
            'offset_y': 0.0,
          });
          mediaFiles.add({
            'type': 'image',
            'file': mediaItem.file,
            'fileName': fileName,
            'path': filePath,
          });
          imageOrder++;
        }
      }

      // 2. 포트폴리오 생성 API 호출 (파일 경로만 전송)
      final now = DateTime.now();
      final workDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final title = content.isEmpty
          ? '새 포트폴리오'
          : (content.length > 50 ? '${content.substring(0, 50)}...' : content);

      final response = await _authService.createPortfolio(
        title: title,
        description: content.isEmpty ? '포트폴리오 설명' : content,
        workDate: workDate,
        price: 0,
        isPublic: true,
        images: imagePaths,
        tags: extractedTags,
        videos: videoPaths.isNotEmpty ? videoPaths : null,
      );

      if (!context.mounted) return false;

      if (response.success) {
        // 3. API 성공 시 실제 파일 업로드
        bool uploadSuccess = true;
        for (var mediaFile in mediaFiles) {
          if (mediaFile['type'] == 'video') {
            // generateVideoPath에서 생성한 파일명 사용
            final videoFileName = mediaFile['path'] as String;
            
            final uploadResult = await _storageService.uploadVideo(
              mediaFile['file'] as File,
              mediaFile['fileName'] as String,
              videoFileName: videoFileName,
            );
            if (uploadResult == null) {
              uploadSuccess = false;
              debugPrint('비디오 업로드 실패: ${mediaFile['fileName']}');
            }
          } else {
            // generateImagePath에서 생성한 경로 사용 (앞의 / 제거)
            final objectKey = (mediaFile['path'] as String).startsWith('/')
                ? (mediaFile['path'] as String).substring(1)
                : mediaFile['path'] as String;
            
            final uploadResult = await _storageService.uploadImage(
              mediaFile['file'] as File,
              mediaFile['fileName'] as String,
              objectKey: objectKey,
            );
            if (uploadResult == null) {
              uploadSuccess = false;
              debugPrint('이미지 업로드 실패: ${mediaFile['fileName']}');
            }
          }
        }

        if (uploadSuccess) {
          // 키보드 닫기
          FocusScope.of(context).unfocus();
          SnackBarHelper.showSuccess(context, '게시물이 등록되었습니다.');
          Navigator.of(context).pop();
          return true;
        } else {
          SnackBarHelper.showError(context, '파일 업로드 중 일부 파일이 실패했습니다.');
          return false;
        }
      } else {
        SnackBarHelper.showError(context, response.message);
        return false;
      }
    } catch (e) {
      debugPrint('게시물 등록 에러: $e');
      if (context.mounted) {
        SnackBarHelper.showError(context, '게시물 등록 중 오류가 발생했습니다.');
      }
      return false;
    }
  }
}

