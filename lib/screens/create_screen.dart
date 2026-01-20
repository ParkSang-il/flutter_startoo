import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/ncp_storage_service.dart';
import '../utils/snackbar_helper.dart';
import 'feed/controllers/tag_highlight_controller.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

// 미디어 타입을 구분하기 위한 클래스
class MediaItem {
  final File file;
  final bool isVideo;
  
  MediaItem({required this.file, required this.isVideo});
}

class _CreateScreenState extends State<CreateScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // --- 2. 컨트롤러 교체 ---
  final TagHighlightController _captionController = TagHighlightController();

  final AuthService _authService = AuthService();
  final NcpStorageService _storageService = NcpStorageService();
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  List<MediaItem> _mediaItems = []; // 이미지와 비디오를 순서대로 관리
  bool _isUploading = false;
  Map<int, VideoPlayerController?> _videoControllers = {}; // 비디오 컨트롤러 저장
  Map<int, bool> _videoPlaying = {}; // 비디오 재생 상태 저장

  // 태그 추출 로직
  List<String> _extractTags(String text) {
    final RegExp hashtagRegex = RegExp(r"#([a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ가-힣\_]+)");
    // 중복 제거를 위해 Set으로 변환 후 다시 List로 반환
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
  }

  // 미디어 선택 (이미지/비디오 통합)
  Future<void> _pickMedia() async {
    try {
      // pickMedia를 사용하여 이미지와 비디오를 함께 선택
      // pickMedia는 단일 선택이지만, 반복 호출로 여러 개 선택 가능
      // 또는 pickMultipleMedia가 지원되는 경우 사용
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
      
      if (medias.isNotEmpty) {
        for (var media in medias) {
          final file = File(media.path);
          final extension = path.extension(media.path).toLowerCase();
          
          // 비디오인지 확인 (확장자로 판단)
          final isVideo = extension == '.mp4' || extension == '.mov' || extension == '.avi' || 
                         extension == '.mkv' || extension == '.webm' || extension == '.m4v';
          
          if (isVideo) {
            // mp4 확장자만 허용
            if (extension != '.mp4') {
              if (mounted) {
                SnackBarHelper.showError(context, '비디오는 mp4 확장자만 허용됩니다.');
              }
              continue;
            }
            
            // 비디오 길이 체크 (1분 30초 = 90초)
            await _validateAndAddVideo(file);
          } else {
            // 이미지 처리
            setState(() {
              _selectedImages.add(file);
              _mediaItems.add(MediaItem(file: file, isVideo: false));
            });
          }
        }
      }
    } catch (e) {
      debugPrint('미디어 선택 에러: $e');
      if (mounted) {
        SnackBarHelper.showError(context, '미디어 선택 중 오류가 발생했습니다.');
      }
    }
  }

  // 비디오 검증 및 추가
  Future<void> _validateAndAddVideo(File videoFile) async {
    try {
      final videoController = VideoPlayerController.file(videoFile);
      await videoController.initialize();
      final duration = videoController.value.duration;
      await videoController.dispose();

      if (duration.inSeconds > 90) {
        if (mounted) {
          SnackBarHelper.showError(context, '비디오는 1분 30초 이하여야 합니다.');
        }
        return;
      }

      setState(() {
        _selectedVideos.add(videoFile);
        _mediaItems.add(MediaItem(file: videoFile, isVideo: true));
      });
    } catch (e) {
      debugPrint('비디오 길이 체크 에러: $e');
      if (mounted) {
        SnackBarHelper.showError(context, '비디오를 읽을 수 없습니다.');
      }
    }
  }

  // _pickImages와 _pickVideo는 _pickMedia로 통합되어 사용되지 않음

  @override
  void dispose() {
    _captionController.dispose();
    // 비디오 컨트롤러 정리
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  // --- 3. 게시글 등록 로직 수정 ---
  Future<void> _submitPost() async {
    if (_mediaItems.isEmpty) {
      SnackBarHelper.showError(context, '이미지 또는 비디오를 최소 1개 이상 선택해주세요.');
      return;
    }

    final String content = _captionController.text.trim();
    // 텍스트에서 태그 리스트 추출
    final List<String> extractedTags = _extractTags(content);

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. 파일 경로만 미리 생성 (업로드하지 않음)
      List<Map<String, dynamic>> imagePaths = [];
      List<Map<String, dynamic>> videoPaths = [];
      List<Map<String, dynamic>> mediaFiles = []; // 실제 파일과 경로 정보 저장
      int videoOrder = 0;
      int imageOrder = 0;
      bool hasVideoBefore = false; // 이미지 앞에 비디오가 있는지 확인

      for (var mediaItem in _mediaItems) {
        if (mediaItem.isVideo) {
          // 비디오 파일 경로 생성 (업로드하지 않음)
          final fileName = path.basename(mediaItem.file.path);
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
          final filePath = _storageService.generateImagePath(fileName);

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

      if (mounted) {
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
          } else {
            SnackBarHelper.showError(context, '파일 업로드 중 일부 파일이 실패했습니다.');
            setState(() { _isUploading = false; });
          }
        } else {
          SnackBarHelper.showError(context, response.message);
          setState(() { _isUploading = false; });
        }
      }
    } catch (e) {
      debugPrint('게시물 등록 에러: $e');
      if (mounted) {
        SnackBarHelper.showError(context, '게시물 등록 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftThreadLine(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final username = authProvider.currentUser?.username ?? '사용자';
                            return Text(
                              username,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            );
                          },
                        ),
                        _buildTextField(),
                        if (_mediaItems.isNotEmpty)
                          _buildMediaPreview(),
                        const SizedBox(height: 12),
                        _buildActionIcons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _isUploading ? null : () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 14,
                color: _isUploading ? Colors.grey : Colors.white,
              ),
            ),
          ),
          const Text('새 포트폴리오', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          _isUploading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
          )
              : GestureDetector(
            onTap: _mediaItems.isEmpty ? null : _submitPost,
            child: Text(
              '게시',
              style: TextStyle(
                fontSize: 14,
                color: _mediaItems.isEmpty ? Colors.blue.withOpacity(0.4) : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftThreadLine() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final profileImage = authProvider.currentUser?.profileImage;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              backgroundImage: profileImage != null && profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileImage == null || profileImage.isEmpty ? const FaIcon(FontAwesomeIcons.user, size: 18, color: Colors.white) : null,
            ),
            const SizedBox(height: 8),
            Container(width: 2, height: 100, color: Colors.grey.shade800),
            CircleAvatar(radius: 10, backgroundColor: Colors.grey.shade900),
          ],
        );
      },
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _captionController,
      maxLines: null,
      onChanged: (val) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        hintText: '새로운 소식이 있나요?',
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = _mediaItems[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: mediaItem.isVideo
                      ? _buildVideoPreview(index, mediaItem)
                      : Image.file(mediaItem.file, height: 240, width: 180, fit: BoxFit.cover),
                ),
                if (mediaItem.isVideo)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIDEO',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        final item = _mediaItems[index];
                        if (item.isVideo) {
                          // 비디오 컨트롤러 정리
                          final controller = _videoControllers[index];
                          controller?.dispose();
                          _videoControllers.remove(index);
                          _videoPlaying.remove(index);
                          _selectedVideos.remove(item.file);
                        } else {
                          _selectedImages.remove(item.file);
                        }
                        _mediaItems.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const FaIcon(FontAwesomeIcons.xmark, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 비디오 미리보기 위젯
  Widget _buildVideoPreview(int index, MediaItem mediaItem) {
    final controller = _videoControllers[index];
    final isPlaying = _videoPlaying[index] ?? false;

    return Container(
      height: 240,
      width: 180,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 비디오 플레이어 또는 플레이스홀더
          if (controller != null && controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )
          else
            Container(color: Colors.black),
          // 재생 버튼 오버레이
          if (!isPlaying || controller == null || !controller.value.isInitialized)
            GestureDetector(
              onTap: () => _toggleVideoPlay(index, mediaItem.file),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.circlePlay, size: 64, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 비디오 재생 토글
  Future<void> _toggleVideoPlay(int index, File videoFile) async {
    try {
      final controller = _videoControllers[index];
      
      if (controller == null || !controller.value.isInitialized) {
        // 비디오 초기화
        final videoController = VideoPlayerController.file(videoFile);
        await videoController.initialize();
        
        if (mounted) {
          setState(() {
            _videoControllers[index] = videoController;
            _videoPlaying[index] = true;
          });
          videoController.play();
          videoController.setLooping(true);
        }
      } else {
        // 재생/일시정지 토글
        if (controller.value.isPlaying) {
          controller.pause();
          setState(() {
            _videoPlaying[index] = false;
          });
        } else {
          controller.play();
          setState(() {
            _videoPlaying[index] = true;
          });
        }
      }
    } catch (e) {
      debugPrint('비디오 재생 에러: $e');
    }
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickMedia,
          child: FaIcon(FontAwesomeIcons.image, color: Colors.grey.shade500, size: 22),
        ),
        const SizedBox(width: 20),
        FaIcon(FontAwesomeIcons.camera, color: Colors.grey.shade500, size: 22),
      ],
    );
  }
}