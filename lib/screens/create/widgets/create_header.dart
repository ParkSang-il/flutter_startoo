import 'package:flutter/material.dart';
import '../controllers/create_screen_controller.dart';

class CreateHeader extends StatelessWidget {
  final CreateScreenController controller;
  final VoidCallback onSubmit;

  const CreateHeader({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: controller.isUploading ? null : () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 14,
                color: controller.isUploading ? Colors.grey : Colors.white,
              ),
            ),
          ),
          const Text('새 포트폴리오', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          controller.isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : GestureDetector(
                  onTap: controller.mediaItems.isEmpty ? null : onSubmit,
                  child: Text(
                    '게시',
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.mediaItems.isEmpty
                          ? Colors.blue.withOpacity(0.4)
                          : Colors.blue,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

