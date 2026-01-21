import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../utils/snackbar_helper.dart';
import '../model/media_item.dart';
import 'video_validation_service.dart';

// 미디어 선택 서비스
class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();

  // 미디어 선택 (이미지/비디오 통합)
  Future<List<MediaItem>> pickMedia(BuildContext context) async {
    try {
      List<XFile> medias = [];
      
      // pickMultipleMedia 시도 (최신 버전에서 지원)
      try {
        medias = await _imagePicker.pickMultipleMedia();
      } catch (e) {
        // pickMultipleMedia가 지원되지 않는 경우
        // pickMedia를 반복 호출하거나 pickMultiImage 사용
        debugPrint('pickMultipleMedia 미지원, pickMultiImage 사용: $e');
        final images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          medias = images;
        }
      }

      // 선택한 파일이 없으면(취소) 빈 리스트 반환
      if (medias.isEmpty) {
        return [];
      }

      List<MediaItem> mediaItems = [];

      for (var media in medias) {
        final file = File(media.path);
        final extension = path.extension(media.path).toLowerCase();
        
        // 비디오인지 확인 (확장자로 판단)
        final isVideo = extension == '.mp4' || extension == '.mov' || extension == '.avi' || 
                       extension == '.mkv' || extension == '.webm' || extension == '.m4v';
        
        if (isVideo) {
          // mp4와 mov 확장자 허용 (아이폰 동영상 지원)
          if (extension != '.mp4' && extension != '.mov') {
            if (context.mounted) {
              SnackBarHelper.showError(context, '비디오는 mp4 또는 mov 확장자만 허용됩니다.');
            }
            continue;
          }
          
          // 비디오 길이 체크 (1분 30초 = 90초)
          final validatedVideo = await VideoValidationService.validateAndAddVideo(file, context);
          if (validatedVideo != null) {
            mediaItems.add(validatedVideo);
          }
        } else {
          // 이미지 처리
          await Future.delayed(const Duration(milliseconds: 100)); // 이미지 로드 시간 확보
          mediaItems.add(MediaItem(file: file, isVideo: false));
        }
      }

      return mediaItems;
    } catch (e) {
      debugPrint('미디어 선택 에러: $e');
      if (context.mounted) {
        SnackBarHelper.showError(context, '미디어 선택 중 오류가 발생했습니다.');
      }
      return [];
    }
  }
}

