import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/create_screen_controller.dart';
import 'create_video_preview.dart';

class CreateMediaPreview extends StatelessWidget {
  final CreateScreenController controller;
  final VoidCallback setState;

  const CreateMediaPreview({
    super.key,
    required this.controller,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = controller.mediaItems[index];
          final isProcessing = controller.mediaProcessing[mediaItem.file.path] ?? false;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isProcessing
                      ? Container(
                          height: 240,
                          width: 180,
                          color: Colors.grey.shade900,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : (mediaItem.isVideo
                          ? CreateVideoPreview(
                              index: index,
                              mediaItem: mediaItem,
                              controller: controller,
                              setState: setState,
                            )
                          : Image.file(
                              mediaItem.file,
                              height: 240,
                              width: 180,
                              fit: BoxFit.cover,
                            )),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => controller.removeMedia(index, setState),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 16,
                        color: Colors.white,
                      ),
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
}

