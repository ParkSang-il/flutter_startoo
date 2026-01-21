import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/portfolio_model.dart';

// ImageDetailScreen 컨트롤러
class ImageDetailController {
  late int currentIndex;
  late PageController pageController;
  Map<int, VideoPlayerController?> videoControllers = {};
  Map<int, bool> videoInitialized = {};
  Map<int, int> videoRetryCount = {}; // 비디오 재시도 횟수 저장
  Map<int, bool> isMuted = {}; // 비디오 음소거 상태 (기본값: true)
  Map<int, bool> showMuteAnimation = {}; // 음소거 상태 변경 애니메이션 표시 여부
  late List<PortfolioMedia> mediaList;
  late int itemCount;

  void initialize(List<PortfolioMedia> mediaList, int initialIndex) {
    this.mediaList = mediaList;
    itemCount = mediaList.length;
    currentIndex = initialIndex;
    pageController = PageController(initialPage: initialIndex);
  }

  void dispose() {
    pageController.dispose();
    for (var controller in videoControllers.values) {
      controller?.dispose();
    }
    videoControllers.clear();
  }

  // 비디오 초기화
  void initializeVideos({
    required bool mounted,
    required VoidCallback setState,
  }) {
    for (int i = 0; i < mediaList.length; i++) {
      final media = mediaList[i];
      if (media.isVideo && media.isVideoComplete) {
        final videoUrl = media.videoUrl ?? media.videoFilePath;
        if (videoUrl != null) {
          initializeVideo(
            i,
            videoUrl,
            mounted: mounted,
            setState: setState,
          );
        }
      }
    }
  }

  Future<void> initializeVideo(
    int index,
    String? videoUrl, {
    int retryCount = 0,
    required bool mounted,
    required VoidCallback setState,
  }) async {
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    // 최대 2회 재시도
    if (retryCount > 2) {
      debugPrint('비디오 초기화 실패: 최대 재시도 횟수 초과');
      if (mounted) {
        videoInitialized[index] = false;
        setState();
      }
      return;
    }

    try {
      String fullVideoUrl = videoUrl;
      if (!videoUrl.startsWith('http')) {
        final path = videoUrl.startsWith('/') ? videoUrl : '/$videoUrl';
        fullVideoUrl = 'https://kr.object.ncloudstorage.com/startoo-vod$path';
      }

      // 이전 컨트롤러가 있으면 정리
      final existingController = videoControllers[index];
      if (existingController != null) {
        try {
          await existingController.dispose();
        } catch (e) {
          debugPrint('기존 컨트롤러 정리 중 에러: $e');
        }
        videoControllers.remove(index);
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(fullVideoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // 타임아웃 설정 (30초)
      await controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          controller.dispose();
          throw TimeoutException('비디오 초기화 타임아웃');
        },
      );

      if (mounted) {
        videoControllers[index] = controller;
        videoInitialized[index] = true;
        this.videoRetryCount[index] = retryCount;
        isMuted[index] = true; // 기본 음소거 상태
        showMuteAnimation[index] = false;
        setState();
        // 기본 음소거 설정
        controller.setVolume(0.0);
        // 현재 슬라이드가 이 비디오인 경우에만 자동 재생
        if (currentIndex == index) {
          // 다른 모든 비디오 일시정지 후 재생
          pauseAllVideos();
          controller.play();
        }
        controller.setLooping(true);
      }
    } catch (e) {
      debugPrint('비디오 초기화 에러 (재시도 $retryCount/2): $e');
      debugPrint('비디오 URL: $videoUrl');

      // 에러 발생 시 컨트롤러 정리
      final existingController = videoControllers[index];
      if (existingController != null) {
        try {
          await existingController.dispose();
        } catch (disposeError) {
          debugPrint('에러 발생 후 컨트롤러 정리 중 에러: $disposeError');
        }
        videoControllers.remove(index);
      }

      if (mounted) {
        videoInitialized[index] = false;
        setState();

        // 재시도 (1초 대기 후)
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 1));
          initializeVideo(
            index,
            videoUrl,
            retryCount: retryCount + 1,
            mounted: mounted,
            setState: setState,
          );
        }
      }
    }
  }

  // 음소거 토글
  void toggleMute(int index, VoidCallback setState) {
    final controller = videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final muted = isMuted[index] ?? true;

    isMuted[index] = !muted;

    // 음소거 상태 변경 시 애니메이션 표시
    showMuteAnimation[index] = true;

    if (!muted) {
      // 음소거 해제
      controller.setVolume(1.0);
    } else {
      // 음소거 설정
      controller.setVolume(0.0);
    }
    setState();
  }

  // 모든 비디오 일시정지
  void pauseAllVideos() {
    for (var entry in videoControllers.entries) {
      final controller = entry.value;
      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  // 특정 비디오 재생 (다른 모든 비디오는 일시정지)
  void playVideo(int index) {
    // 먼저 모든 비디오 일시정지
    pauseAllVideos();

    // 현재 비디오만 재생
    final controller = videoControllers[index];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
    }
  }

  void onPageChanged(int index, VoidCallback setState) {
    currentIndex = index;
    setState();
    // 현재 슬라이드가 비디오가 아니면 모든 비디오 일시정지
    pauseAllVideos();
    // 현재 슬라이드가 비디오이면 재생
    final currentMedia = mediaList[index];
    if (currentMedia.isVideo && currentMedia.isVideoComplete) {
      playVideo(index);
    }
  }
}

