import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/create_screen_controller.dart';

class CreateActionIcons extends StatelessWidget {
  final CreateScreenController controller;
  final VoidCallback onPickMedia;

  const CreateActionIcons({
    super.key,
    required this.controller,
    required this.onPickMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.isPickingMedia ? null : onPickMedia,
          child: controller.isPickingMedia
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : FaIcon(
                  FontAwesomeIcons.image,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
        ),
        const SizedBox(width: 20),
        FaIcon(
          FontAwesomeIcons.camera,
          color: Colors.grey.shade500,
          size: 22,
        ),
      ],
    );
  }
}

