import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../model/FeedModel.dart';
import '../image_detail_screen.dart';
import '../../../utils/tag_helper.dart';
import '../../../utils/number_formatter.dart';
import '../../../utils/image_url_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/snackbar_helper.dart';
import 'comment_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../models/portfolio_model.dart';

class FeedItem extends StatefulWidget {
  final FeedModel feed;
  final VoidCallback? onCommentAdded; // 댓글 작성 후 콜백
  const FeedItem({super.key, required this.feed, this.onCommentAdded});

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  static const int _maxLines = 3; // 최대 표시 줄 수
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLiking = false;
  Map<int, double> _imageAspectRatios = {}; // 이미지 인덱스별 비율 저장
  Map<int, bool> _imageLoaded = {}; // 이미지 로드 상태 저장
  Map<int, bool> _imageError = {}; // 이미지 에러 상태 저장
  Map<int, VideoPlayerController?> _videoControllers = {}; // 비디오 컨트롤러 저장
  Map<int, bool> _videoInitialized = {}; // 비디오 초기화 상태 저장
  Map<int, bool> _videoVisible = {}; // 비디오 가시성 상태 저장
  Map<int, int> _videoRetryCount = {}; // 비디오 재시도 횟수 저장
  int? _currentPlayingVideoIndex; // 현재 재생 중인 비디오 인덱스

  @override
  void initState() {
    super.initState();
    _isLiked = widget.feed.isLiked;
    _likesCount = widget.feed.likes;
    
    // 비디오 자동 재생 초기화
    _initializeVideos();
  }

  @override
  void dispose() {
    // 비디오 컨트롤러 정리
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  // 비디오 초기화 및 자동 재생
  void _initializeVideos() {
    for (int i = 0; i < widget.feed.media.length; i++) {
      final media = widget.feed.media[i];
      if (media.isVideo && media.isVideoComplete) {
        // video_status가 complete인 경우에만 비디오 초기화
        // video_url이 있으면 HLS URL(m3u8) 또는 일반 비디오 URL로 사용
        // video_url이 없으면 video_file_path 사용
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
      // 비디오 URL 구성
      String fullVideoUrl = videoUrl;
      
      // HLS URL (m3u8) 또는 전체 URL인 경우 그대로 사용
      // video_url은 콜백 후 HLS 형식으로 들어옴:
      // https://yypo7c7k13595.edge.naverncp.com/hls/.../index.m3u8
      if (!videoUrl.startsWith('http')) {
        // 상대 경로인 경우 (video_file_path 사용 시)
        // startoo-vod 버킷 URL 구성
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

      // video_player는 HLS URL(.m3u8)을 자동으로 인식하여 처리
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
        // 초기화만 하고 재생은 하지 않음 (가시성 감지 후 재생)
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

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.toggleLike(widget.feed.portfolioId, _isLiked);

    if (mounted) {
      setState(() {
        _isLiking = false;
      });

      if (response.success && response.data != null) {
        setState(() {
          _isLiked = response.data!.isLiked;
          _likesCount = response.data!.likesCount;
        });
      } else {
        SnackBarHelper.showError(context, response.message);
      }
    }
  }

  // 더보기 메뉴 표시
  void _showMoreMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isOwnPortfolio = currentUserId != null && currentUserId == widget.feed.portfolioOwnerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 그랩 바
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 신고하기 버튼 (본인 포트폴리오가 아닌 경우에만 표시)
              if (!isOwnPortfolio) ...[
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.flag, color: Colors.red, size: 24),
                  title: const Text(
                    '신고하기',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportConfirmDialog(context);
                  },
                ),
                const Divider(color: Colors.grey, height: 1),
              ],
              // 취소 버튼
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.xmark, color: Colors.grey, size: 24),
                title: const Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 신고 확인 다이얼로그
  void _showReportConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '신고하기',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '신고하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reportPortfolio(context);
            },
            child: const Text(
              '신고',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 포트폴리오 신고
  Future<void> _reportPortfolio(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.reportPortfolio(widget.feed.portfolioId);

    if (mounted) {
      if (response.success) {
        SnackBarHelper.showSuccess(
          context,
          '빠르게 검토하도록 하겠습니다. 감사합니다.',
        );
      } else {
        SnackBarHelper.showError(context, response.message);
      }
    }
  }

  @override
  bool get wantKeepAlive => false; // 스크롤 밖 위젯은 dispose하여 메모리 절약

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요
    final colorOnSurface = Theme.of(context).colorScheme.onSurface;
    final caption = widget.feed.caption;
    final needsExpansion = _needsExpansion(caption);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 프로필 이미지 & 스레드 라인
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    ImageUrlHelper.buildGeneralImageUrl(widget.feed.userImage),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(width: 12),

            // 우측: 콘텐츠 영역
            Expanded(
              child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  // 1. 헤더 (이름 + 시간 + 더보기)
                  Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    widget.feed.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.feed.timeAgo,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
                      GestureDetector(
                        onTap: () => _showMoreMenu(context),
                        child: FaIcon(FontAwesomeIcons.ellipsis, color: Colors.grey.shade500),
                      ),
                    ],
                  ),

                  // 2. 캡션
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCaptionText(caption, colorOnSurface),
                        if (needsExpansion)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Text(
                                    _isExpanded ? '접기' : '더 보기',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  FaIcon(
                                    _isExpanded
                                        ? FontAwesomeIcons.chevronUp
                                        : FontAwesomeIcons.chevronDown,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
            ],
          ),
        ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. 미디어 섹션 (이미지 + 비디오)
                  if (widget.feed.media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildFlexibleMediaSection(),
                    ),

                  // 4. 액션 버튼
              Row(
                children: [
                      _buildLikeButton(),
                      _buildCommentButton(),
                      _buildActionButton(FontAwesomeIcons.repeat),
                      _buildActionButton(FontAwesomeIcons.paperPlane),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
    );
  }

  // 태그를 하이라이트한 텍스트 위젯
  Widget _buildCaptionText(String text, Color defaultColor) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TagHelper.buildTagHighlightTextSpan(
        text: text,
        baseStyle: TextStyle(color: defaultColor, fontSize: 14),
      ),
      maxLines: _isExpanded ? null : _maxLines,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  // 텍스트가 확장이 필요한지 확인
  bool _needsExpansion(String text) {
    if (text.isEmpty) return false;
    
    // TextPainter를 사용하여 실제 렌더링된 줄 수 확인
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14),
      ),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: double.infinity);
    
    // 실제 줄 수가 maxLines보다 많으면 확장 필요
    return textPainter.didExceedMaxLines;
  }

  Widget _buildLikeButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: _isLiking ? null : _toggleLike,
        child: Row(
          mainAxisSize: MainAxisSize.min,
            children: [
            _isLiking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : FaIcon(
                    FontAwesomeIcons.heart,
                    size: 22,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
            const SizedBox(width: 4),
              Text(
              NumberFormatter.formatCount(_likesCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCommentButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          final modalContext = context; // 모달을 연 원본 context 저장
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CommentModal(
              portfolioId: widget.feed.portfolioId,
              portfolioOwnerId: widget.feed.portfolioOwnerId,
              parentContext: modalContext, // 원본 context 전달
            ),
          ).then((shouldRefresh) {
            // 댓글 작성 후 피드 리스트 새로고침
            if (shouldRefresh == true && mounted && widget.onCommentAdded != null) {
              widget.onCommentAdded!();
            }
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.comment, size: 22, color: Colors.white),
            const SizedBox(width: 4),
              Text(
              NumberFormatter.formatCount(widget.feed.comments),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            ],
          ),
        ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }

  // 미디어 섹션 빌더 (이미지 + 비디오 통합)
  Widget _buildFlexibleMediaSection() {
    final media = widget.feed.media;

    // 1. 미디어가 하나일 때
    if (media.length == 1) {
      return _buildSingleMedia(media.first);
    }

    // 2. 미디어가 여러 개일 때 (가로 사이즈 가변형)
    return _buildVariableWidthMediaSlider(media);
  }

  // 단일 미디어 (이미지 또는 비디오)
  Widget _buildSingleMedia(portfolioMedia) {
    if (portfolioMedia.isVideo) {
      return _buildSingleVideo(portfolioMedia, 0);
    } else {
      return _buildSingleImage(portfolioMedia.imageUrl ?? '');
    }
  }

  // 단일 비디오
  Widget _buildSingleVideo(portfolioMedia, int index) {
    double videoRatio = 0.8; // 기본 세로형 비율

    return AspectRatio(
      aspectRatio: videoRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildVideoPlayer(index, portfolioMedia),
      ),
    );
  }

  // 단일 이미지: 비율에 따라 박스 크기 변경
  Widget _buildSingleImage(String imageUrl) {
    // 실제로는 이미지 메타데이터(가로/세로)를 사용해야 합니다.
    // TODO: API에서 이미지 width, height 정보를 받아와서 정확한 비율 계산
    double imageRatio = 0.8; // 기본 세로형 (Tattoo에 최적)

    return AspectRatio(
      aspectRatio: imageRatio,
      child: GestureDetector(
        onTap: () {
          // mediaList를 전달하여 이미지와 비디오 모두 포함
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageDetailScreen(
                mediaList: widget.feed.media,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImageWithSkeleton(
            imageUrl,
            0,
          ),
        ),
      ),
    );
  }

  // 다중 미디어: 높이 고정, 너비 가변 (이미지 + 비디오)
  Widget _buildVariableWidthMediaSlider(List media) {
    // 최대 높이 설정 (한 번만 계산)
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxHeight = screenWidth * 0.8;
    
    // 가로형/세로형 이미지에 대한 고정 비율
    const double landscapeRatio = 0.9;
    const double portraitRatio = 0.7;

    return SizedBox(
      height: maxHeight,
      child: ClipRect(
        clipper: RightSideNoneClipper(),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          cacheExtent: 500,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final mediaItem = media[index];
            double fixedRatio = 0.8;
            
            if (mediaItem.isImage) {
              final originalRatio = _imageAspectRatios[index] ?? 0.8;
              fixedRatio = originalRatio > 1.0 ? landscapeRatio : portraitRatio;
            } else {
              fixedRatio = portraitRatio; // 비디오는 세로형 비율
            }
            
            final calculatedWidth = maxHeight * fixedRatio;

            return GestureDetector(
              onTap: () {
                // 이미지 또는 비디오 상세 화면으로 이동 (모든 미디어 포함)
                final mediaList = List<PortfolioMedia>.from(media);
                final mediaIndex = mediaList.indexOf(mediaItem);
                
                if (mediaIndex >= 0) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ImageDetailScreen(
                        mediaList: mediaList,
                        initialIndex: mediaIndex,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: calculatedWidth,
                    height: maxHeight,
                    child: mediaItem.isVideo
                        ? _buildVideoPlayer(index, mediaItem)
                        : _buildImageWithRatioDetection(
                            mediaItem.imageUrl ?? '',
                            index,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 비디오 플레이어 위젯
  Widget _buildVideoPlayer(int index, portfolioMedia) {
    // 비디오 상태 확인
    final isEncoding = portfolioMedia.isVideoEncoding;
    
    // 인코딩 중인 경우
    if (isEncoding) {
      return _buildEncodingIndicator(portfolioMedia);
    }

    // 비디오 썸네일이 있으면 먼저 표시
    final thumbnailUrl = portfolioMedia.videoThumbnailUrl;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    if ((_videoInitialized[index] ?? false) == false) {
      // 비디오 초기화 중 - 스켈레톤 UI 표시
      return Stack(
        fit: StackFit.expand,
        children: [
          // 스켈레톤 UI
          _buildSkeleton(),
          // 썸네일이 있으면 표시 (로딩 중 스켈레톤 위에)
          if (hasThumbnail)
            Image.network(
              thumbnailUrl!.startsWith('http')
                  ? thumbnailUrl
                  : 'https://kr.object.ncloudstorage.com/startoo-vod${thumbnailUrl.startsWith('/') ? thumbnailUrl : '/$thumbnailUrl'}',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                // 썸네일 로딩 중이면 스켈레톤 유지
                if (loadingProgress == null) {
                  return child;
                }
                return const SizedBox.shrink();
              },
              errorBuilder: (context, error, stackTrace) {
                // 에러 시 스켈레톤만 표시
                return const SizedBox.shrink();
              },
            ),
          // 비디오 타입 표시
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      // 비디오 초기화 실패 - 썸네일 표시
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumbnail)
              Image.network(
                thumbnailUrl!.startsWith('http')
                    ? thumbnailUrl
                    : 'https://kr.object.ncloudstorage.com/startoo-vod${thumbnailUrl.startsWith('/') ? thumbnailUrl : '/$thumbnailUrl'}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.videoSlash, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            '비디오를 재생할 수 없습니다',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.videoSlash, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        '비디오를 재생할 수 없습니다',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            // 비디오 타입 표시
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return VisibilityDetector(
      key: Key('video_${widget.feed.portfolioId}_$index'),
      onVisibilityChanged: (VisibilityInfo info) {
        final isVisible = info.visibleFraction > 0.5; // 50% 이상 보일 때만 재생
        
        if (mounted) {
          setState(() {
            _videoVisible[index] = isVisible;
          });
          
          if (isVisible) {
            // 다른 비디오가 재생 중이면 일시정지
            if (_currentPlayingVideoIndex != null && _currentPlayingVideoIndex != index) {
              final otherController = _videoControllers[_currentPlayingVideoIndex];
              if (otherController != null && otherController.value.isPlaying) {
                otherController.pause();
              }
            }
            // 현재 비디오 재생
            if (controller.value.isInitialized && !controller.value.isPlaying) {
              controller.play();
              _currentPlayingVideoIndex = index;
            }
          } else {
            // 화면에서 벗어나면 일시정지
            if (controller.value.isPlaying) {
              controller.pause();
            }
            if (_currentPlayingVideoIndex == index) {
              _currentPlayingVideoIndex = null;
            }
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 비디오 플레이어 (레이아웃에 맞게 자르기)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          // 비디오 타입 표시
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 인코딩 중 표시 위젯
  Widget _buildEncodingIndicator(portfolioMedia) {
    final thumbnailUrl = portfolioMedia.videoThumbnailUrl;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 썸네일 표시 (있는 경우)
          if (hasThumbnail)
            Image.network(
              thumbnailUrl!.startsWith('http')
                  ? thumbnailUrl
                  : 'https://kr.object.ncloudstorage.com/startoo-vod${thumbnailUrl.startsWith('/') ? thumbnailUrl : '/$thumbnailUrl'}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.black);
              },
            )
          else
            Container(color: Colors.black),
          // 인코딩 중 오버레이
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Text(
                '인코딩 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 비디오 타입 표시
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 다중 이미지: 높이 고정, 너비 가변 (하위 호환성) - 사용되지 않음
  // ignore: unused_element
  Widget _buildVariableWidthSlider(List<String> images) {
    // 최대 높이 설정 (한 번만 계산)
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxHeight = screenWidth * 0.8;
    
    // 가로형/세로형 이미지에 대한 고정 비율
    const double landscapeRatio = 0.9;
    const double portraitRatio = 0.7;

    return SizedBox(
      height: maxHeight,
      child: ClipRect(
        clipper: RightSideNoneClipper(),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          physics: const BouncingScrollPhysics(), // 기본 물리 효과
          clipBehavior: Clip.none,
          cacheExtent: 500, // 캐시 범위 최적화
          addAutomaticKeepAlives: false, // 메모리 최적화
          addRepaintBoundaries: true, // 리페인트 최적화
          itemBuilder: (context, index) {
            // 비율 계산 최적화
            final originalRatio = _imageAspectRatios[index] ?? 0.8;
            final fixedRatio = originalRatio > 1.0 ? landscapeRatio : portraitRatio;
            final calculatedWidth = maxHeight * fixedRatio;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImageDetailScreen(
                      imageUrls: widget.feed.postImages,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: calculatedWidth,
                    height: maxHeight,
                    child: _buildImageWithRatioDetection(
                      images[index],
                      index,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 이미지 비율 감지가 포함된 이미지 위젯
  Widget _buildImageWithRatioDetection(String imageUrl, int index) {
    // 에러가 발생한 경우 에러 플레이스홀더 표시
    if (_imageError[index] ?? false) {
      return Container(
        color: Colors.grey.shade800,
        child: FaIcon(
          FontAwesomeIcons.image,
          color: Colors.grey.shade600,
          size: 40,
        ),
      );
    }

    // 피드 이미지 URL 생성 (너비 500)
    final feedImageUrl = ImageUrlHelper.buildFeedImageUrl(imageUrl);

    // 비율이 아직 계산되지 않았으면 이미지를 로드하면서 비율 감지
    return Image.network(
      feedImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 1000, // 메모리 최적화: 최대 1000px 너비로 디코딩
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // 프레임이 있고 비율이 아직 계산되지 않았을 때만 계산
        if (frame != null && !_imageAspectRatios.containsKey(index)) {
          // 이미지 프레임에서 크기 정보 가져오기 (한 번만 실행)
          final imageProvider = NetworkImage(feedImageUrl);
          imageProvider.resolve(ImageConfiguration()).addListener(
            ImageStreamListener(
              (ImageInfo imageInfo, bool synchronousCall) {
                if (!_imageAspectRatios.containsKey(index) && mounted) {
                  final imageWidth = imageInfo.image.width.toDouble();
                  final imageHeight = imageInfo.image.height.toDouble();
                  final aspectRatio = imageWidth / imageHeight;

                  // 빌드 중 setState 방지
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_imageAspectRatios.containsKey(index)) {
                      setState(() {
                        _imageAspectRatios[index] = aspectRatio;
                        _imageLoaded[index] = true;
                      });
                    }
                  });
                }
              },
            ),
          );
        }
        return child;
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // 이미지 로드 완료
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _imageLoaded[index] = true;
                });
              }
            });
          }
          return child;
        }
        // 로딩 중이면 스켈레톤 UI 표시
        return _buildSkeleton();
      },
      errorBuilder: (context, error, stackTrace) {
        // 에러 발생 시 에러 상태 저장 및 플레이스홀더 표시 (빌드 중 setState 방지)
        if (mounted && !(_imageError[index] ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !(_imageError[index] ?? false)) {
              setState(() {
                _imageError[index] = true;
              });
            }
          });
        }
        return Container(
          color: Colors.grey.shade800,
          child: FaIcon(
            FontAwesomeIcons.image,
            color: Colors.grey.shade600,
            size: 40,
          ),
        );
      },
    );
  }

  // 스켈레톤 UI 빌더 (shimmer 효과)
  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        color: Colors.grey.shade800,
      ),
    );
  }

  // 단일 이미지용 이미지 위젯 (스켈레톤 포함, 최적화)
  Widget _buildImageWithSkeleton(String imageUrl, int index) {
    // 에러가 발생한 경우 에러 플레이스홀더 표시
    if (_imageError[index] ?? false) {
      return Container(
        color: Colors.grey.shade800,
        child: FaIcon(
          FontAwesomeIcons.image,
          color: Colors.grey.shade600,
          size: 40,
        ),
      );
    }

    // 피드 이미지 URL 생성 (너비 300)
    final feedImageUrl = ImageUrlHelper.buildFeedImageUrl(imageUrl);

    return Image.network(
      feedImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // 이미지 로드 완료 (빌드 중 setState 방지)
          if (mounted && !(_imageLoaded[index] ?? false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !(_imageLoaded[index] ?? false)) {
                setState(() {
                  _imageLoaded[index] = true;
                });
              }
            });
          }
          return child;
        }
        // 로딩 중이면 스켈레톤 UI 표시
        return _buildSkeleton();
      },
      errorBuilder: (context, error, stackTrace) {
        // 에러 발생 시 에러 상태 저장 및 플레이스홀더 표시 (빌드 중 setState 방지)
        if (mounted && !(_imageError[index] ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !(_imageError[index] ?? false)) {
              setState(() {
                _imageError[index] = true;
              });
            }
          });
        }
        return Container(
          color: Colors.grey.shade800,
          child: FaIcon(
            FontAwesomeIcons.image,
            color: Colors.grey.shade600,
            size: 40,
          ),
        );
      },
    );
  }
}

// 왼쪽은 잘리고 오른쪽만 넘쳐보이게 하는 CustomClipper
class RightSideNoneClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // 왼쪽(0,0)부터 시작, 오른쪽은 충분히 넓게 설정하여 오버플로우 허용
    return Rect.fromLTRB(0, 0, size.width + 500, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
