import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/portfolio_model.dart';

// 비디오 플레이어 서비스
class ImageDetailVideoPlayerService {
  // 비디오 플레이어 위젯 빌드
  static Widget buildVideoPlayer(
    int index,
    PortfolioMedia media,
    VideoPlayerController? controller,
    bool isInitialized,
    bool? isMuted,
    bool? showAnimation,
    VoidCallback onToggleMute,
  ) {
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

    if (controller == null || !isInitialized) {
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

    // 가로로만 꽉 차게 표시 (비율 유지)
    return LayoutBuilder(
      builder: (context, constraints) {
        final videoAspectRatio = controller.value.aspectRatio;
        final screenWidth = constraints.maxWidth;
        final videoHeight = screenWidth / videoAspectRatio;
        final muted = isMuted ?? true;
        final showAnim = showAnimation ?? false;

        return GestureDetector(
          onTap: onToggleMute,
          child: Stack(
            children: [
              SizedBox(
                width: screenWidth,
                height: videoHeight,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoAspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              // 음소거 상태 변경 애니메이션
              if (showAnim)
                Positioned.fill(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, opacity, child) {
                        return Opacity(
                          opacity: opacity,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              muted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

