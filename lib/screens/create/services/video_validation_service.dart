import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../utils/snackbar_helper.dart';
import '../model/media_item.dart';

// 비디오 검증 서비스
class VideoValidationService {
  // 비디오 검증 및 추가
  static Future<MediaItem?> validateAndAddVideo(
    File videoFile,
    BuildContext context,
  ) async {
    try {
      final videoController = VideoPlayerController.file(videoFile);
      await videoController.initialize();
      final duration = videoController.value.duration;
      await videoController.dispose();

      if (duration.inSeconds > 90) {
        if (context.mounted) {
          SnackBarHelper.showError(context, '비디오는 1분 30초 이하여야 합니다.');
        }
        return null;
      }

      return MediaItem(file: videoFile, isVideo: true);
    } catch (e) {
      debugPrint('비디오 길이 체크 에러: $e');
      if (context.mounted) {
        SnackBarHelper.showError(context, '비디오를 읽을 수 없습니다.');
      }
      return null;
    }
  }
}

