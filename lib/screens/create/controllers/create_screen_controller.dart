import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../feed/controllers/tag_highlight_controller.dart';
import '../model/media_item.dart';
import '../services/media_picker_service.dart';
import '../services/create_portfolio_service.dart';
import '../services/video_player_service.dart';

// CreateScreen 컨트롤러
class CreateScreenController {
  final TagHighlightController captionController = TagHighlightController();
  final MediaPickerService _mediaPickerService = MediaPickerService();
  final CreatePortfolioService _createPortfolioService = CreatePortfolioService();

  List<File> selectedImages = [];
  List<File> selectedVideos = [];
  List<MediaItem> mediaItems = []; // 이미지와 비디오를 순서대로 관리
  bool isUploading = false;
  bool isPickingMedia = false; // 미디어 선택 중 상태
  bool isOpeningGallery = false; // 갤러리 오픈/선택 UI 동작 중 (로딩 표시 X)
  Map<String, bool> mediaProcessing = {}; // 미디어별 처리 중 상태 (파일 경로를 키로 사용)
  Map<int, VideoPlayerController?> videoControllers = {}; // 비디오 컨트롤러 저장
  Map<int, bool> videoPlaying = {}; // 비디오 재생 상태 저장

  // 미디어 선택
  Future<void> pickMedia(BuildContext context, VoidCallback setState) async {
    // 갤러리 UI가 이미 열려있거나, 선택 후 처리 중이면 중복 실행 방지
    if (isOpeningGallery || isPickingMedia) return;

    isOpeningGallery = true;
    setState();

    try {
      // 갤러리에서 "확인" 후 돌아온 시점
      if (context.mounted) {
        isOpeningGallery = false;
        setState();
      }

      // 미디어 선택
      final pickedItems = await _mediaPickerService.pickMedia(context);

      // 선택한 파일이 없으면(취소) 로딩 표시 없이 종료
      if (pickedItems.isEmpty) {
        return;
      }

      // 여기서부터 실제 처리(검증/추가) 시간: "첨부중" 로딩 표시 ON
      if (context.mounted) {
        isPickingMedia = true;
        setState();
      }

      for (var item in pickedItems) {
        if (context.mounted) {
          mediaProcessing[item.file.path] = true;
          setState();
        }

        if (item.isVideo) {
          selectedVideos.add(item.file);
        } else {
          selectedImages.add(item.file);
        }
        mediaItems.add(item);

        if (context.mounted) {
          mediaProcessing.remove(item.file.path);
          setState();
        }
      }
    } catch (e) {
      debugPrint('미디어 선택 에러: $e');
    } finally {
      if (context.mounted) {
        isOpeningGallery = false;
        isPickingMedia = false;
        setState();
      }
    }
  }

  // 게시글 등록
  Future<void> submitPost(BuildContext context, VoidCallback setState) async {
    isUploading = true;
    setState();

    await _createPortfolioService.submitPost(
      context,
      mediaItems,
      captionController.text.trim(),
    );

    if (context.mounted) {
      isUploading = false;
      setState();
    }
  }

  // 비디오 재생 토글
  Future<void> toggleVideoPlay(
    int index,
    File videoFile,
    bool mounted,
    VoidCallback setState,
  ) async {
    await VideoPlayerService.toggleVideoPlay(
      index,
      videoFile,
      videoControllers,
      videoPlaying,
      mounted,
      setState,
    );
  }

  // 미디어 삭제
  void removeMedia(int index, VoidCallback setState) {
    final item = mediaItems[index];
    if (item.isVideo) {
      // 비디오 컨트롤러 정리
      final controller = videoControllers[index];
      controller?.dispose();
      videoControllers.remove(index);
      videoPlaying.remove(index);
      selectedVideos.remove(item.file);
    } else {
      selectedImages.remove(item.file);
    }
    mediaItems.removeAt(index);
    setState();
  }

  // 리소스 정리
  void dispose() {
    captionController.dispose();
    // 비디오 컨트롤러 정리
    for (var controller in videoControllers.values) {
      controller?.dispose();
    }
    videoControllers.clear();
  }
}

