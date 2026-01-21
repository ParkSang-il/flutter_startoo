import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// 비디오 플레이어 서비스
class VideoPlayerService {
  // 비디오 재생 토글
  static Future<void> toggleVideoPlay(
    int index,
    File videoFile,
    Map<int, VideoPlayerController?> videoControllers,
    Map<int, bool> videoPlaying,
    bool mounted,
    VoidCallback setState,
  ) async {
    try {
      final controller = videoControllers[index];
      
      if (controller == null || !controller.value.isInitialized) {
        // 비디오 초기화
        final videoController = VideoPlayerController.file(videoFile);
        await videoController.initialize();
        
        if (mounted) {
          videoControllers[index] = videoController;
          videoPlaying[index] = true;
          setState();
          videoController.play();
          videoController.setLooping(true);
        }
      } else {
        // 재생/일시정지 토글
        if (controller.value.isPlaying) {
          controller.pause();
          videoPlaying[index] = false;
          setState();
        } else {
          controller.play();
          videoPlaying[index] = true;
          setState();
        }
      }
    } catch (e) {
      debugPrint('비디오 재생 에러: $e');
    }
  }
}

