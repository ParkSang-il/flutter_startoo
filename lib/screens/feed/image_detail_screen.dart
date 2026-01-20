import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/image_url_helper.dart';
import '../../models/portfolio_model.dart';

class ImageDetailScreen extends StatefulWidget {
  final List<String>? imageUrls; // 하위 호환성을 위해 유지
  final List<PortfolioMedia>? mediaList; // 이미지와 비디오 통합 리스트
  final int initialIndex;

  const ImageDetailScreen({
    super.key,
    this.imageUrls,
    this.mediaList,
    this.initialIndex = 0,
  }) : assert(imageUrls != null || mediaList != null, 'imageUrls 또는 mediaList 중 하나는 필수입니다.');

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late int _currentIndex;
  late PageController _pageController;
  Map<int, VideoPlayerController?> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Map<int, int> _videoRetryCount = {}; // 비디오 재시도 횟수 저장
  late List<PortfolioMedia> _mediaList;
  late int _itemCount;

  @override
  void initState() {
    super.initState();
    
    // mediaList가 있으면 사용, 없으면 imageUrls를 PortfolioMedia로 변환
    if (widget.mediaList != null) {
      _mediaList = widget.mediaList!;
    } else {
      // 하위 호환성: imageUrls를 PortfolioMedia 리스트로 변환
      _mediaList = widget.imageUrls!.map((url) => PortfolioMedia(
        type: 'image',
        id: 0,
        imageUrl: url,
        order: 0,
        createdAt: '',
      )).toList();
    }
    
    _itemCount = _mediaList.length;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // 비디오 초기화
    _initializeVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  // 비디오 초기화
  void _initializeVideos() {
    for (int i = 0; i < _mediaList.length; i++) {
      final media = _mediaList[i];
      if (media.isVideo && media.isVideoComplete) {
        final videoUrl = media.videoUrl ?? media.videoFilePath;
        if (videoUrl != null) {
          _initializeVideo(i, videoUrl);
        }
      }
    }
  }

  Future<void> _initializeVideo(int index, String? videoUrl, {int retryCount = 0}) async {
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    // 최대 2회 재시도
    if (retryCount > 2) {
      debugPrint('비디오 초기화 실패: 최대 재시도 횟수 초과');
      if (mounted) {
        setState(() {
          _videoInitialized[index] = false;
        });
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
      final existingController = _videoControllers[index];
      if (existingController != null) {
        try {
          await existingController.dispose();
        } catch (e) {
          debugPrint('기존 컨트롤러 정리 중 에러: $e');
        }
        _videoControllers.remove(index);
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
        setState(() {
          _videoControllers[index] = controller;
          _videoInitialized[index] = true;
          _videoRetryCount[index] = retryCount;
        });
        // 자동 재생
        controller.play();
        controller.setLooping(true);
      }
    } catch (e) {
      debugPrint('비디오 초기화 에러 (재시도 $retryCount/2): $e');
      debugPrint('비디오 URL: $videoUrl');
      
      // 에러 발생 시 컨트롤러 정리
      final existingController = _videoControllers[index];
      if (existingController != null) {
        try {
          await existingController.dispose();
        } catch (disposeError) {
          debugPrint('에러 발생 후 컨트롤러 정리 중 에러: $disposeError');
        }
        _videoControllers.remove(index);
      }
      
      if (mounted) {
        setState(() {
          _videoInitialized[index] = false;
        });
        
        // 재시도 (1초 대기 후)
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 1));
          _initializeVideo(index, videoUrl, retryCount: retryCount + 1);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _itemCount,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final media = _mediaList[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final appBarHeight = AppBar().preferredSize.height;
                  final statusBarHeight = MediaQuery.of(context).padding.top;
                  
                  // 비디오는 화면에 꽉 차게, 이미지는 중앙 정렬
                  if (media.isVideo) {
                    return SizedBox.expand(
                      child: _buildVideoPlayer(index, media),
                    );
                  }
                  
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: (appBarHeight + statusBarHeight) / 2,
                        bottom: _itemCount > 1 ? 50.0 : 0.0,
                      ),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          ImageUrlHelper.buildDetailImageUrl(media.imageUrl ?? ''),
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: FaIcon(
                                FontAwesomeIcons.image,
                                color: Colors.white,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // 점 인디케이터 (하단 중앙)
          if (_itemCount > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _itemCount,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 비디오 플레이어 위젯
  Widget _buildVideoPlayer(int index, PortfolioMedia media) {
    // 인코딩 중인 경우
    if (media.isVideoEncoding) {
      return Center(
        child: Text(
          '인코딩 중...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      // 비디오 초기화 중 - 화면에 꽉 차게 표시
      final thumbnailUrl = media.videoThumbnailUrl;
      return thumbnailUrl != null && thumbnailUrl.isNotEmpty
          ? SizedBox.expand(
              child: Image.network(
                thumbnailUrl.startsWith('http')
                    ? thumbnailUrl
                    : 'https://kr.object.ncloudstorage.com/startoo-vod${thumbnailUrl.startsWith('/') ? thumbnailUrl : '/$thumbnailUrl'}',
                fit: BoxFit.cover,
              ),
            )
          : SizedBox.expand(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
    }

    // 화면에 꽉 차게 표시
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

