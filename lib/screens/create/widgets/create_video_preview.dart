import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import '../controllers/create_screen_controller.dart';
import '../model/media_item.dart';

class CreateVideoPreview extends StatelessWidget {
  final int index;
  final MediaItem mediaItem;
  final CreateScreenController controller;
  final VoidCallback setState;

  const CreateVideoPreview({
    super.key,
    required this.index,
    required this.mediaItem,
    required this.controller,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    final videoController = controller.videoControllers[index];
    final isPlaying = controller.videoPlaying[index] ?? false;

    return Container(
      height: 240,
      width: 180,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 비디오 플레이어 또는 플레이스홀더
          if (videoController != null && videoController.value.isInitialized)
            AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            )
          else
            Container(color: Colors.black),
          // 재생 버튼 오버레이
          if (!isPlaying || videoController == null || !videoController.value.isInitialized)
            GestureDetector(
              onTap: () => controller.toggleVideoPlay(
                index,
                mediaItem.file,
                context.mounted,
                setState,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.circlePlay,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

