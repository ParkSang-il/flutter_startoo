import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../utils/image_url_helper.dart';
import '../controllers/image_detail_controller.dart';
import '../services/video_player_service.dart';

class ImageDetailPageView extends StatelessWidget {
  final ImageDetailController controller;
  final VoidCallback onPageChanged;
  final VoidCallback setState;

  const ImageDetailPageView({
    super.key,
    required this.controller,
    required this.onPageChanged,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller.pageController,
      itemCount: controller.itemCount,
      onPageChanged: (index) {
        controller.onPageChanged(index, setState);
        onPageChanged();
      },
      itemBuilder: (context, index) {
        final media = controller.mediaList[index];
        return LayoutBuilder(
          builder: (context, constraints) {
            // 비디오는 가로로만 꽉 차게 (비율 유지), 이미지는 중앙 정렬
            if (media.isVideo) {
              return Center(
                child: ImageDetailVideoPlayerService.buildVideoPlayer(
                  index,
                  media,
                  controller.videoControllers[index],
                  controller.videoInitialized[index] ?? false,
                  controller.isMuted[index],
                  controller.showMuteAnimation[index],
                  () => controller.toggleMute(index, setState),
                ),
              );
            }

            // 이미지는 가로로 꽉 차게 표시 (비율 유지, 줌 가능)
            return SizedBox.expand(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  ImageUrlHelper.buildDetailImageUrl(media.imageUrl ?? ''),
                  fit: BoxFit.fitWidth, // 가로로 꽉 차게, 비율 유지
                  width: constraints.maxWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
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
            );
          },
        );
      },
    );
  }
}

