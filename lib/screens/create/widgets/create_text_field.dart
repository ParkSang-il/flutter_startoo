import 'package:flutter/material.dart';
import '../controllers/create_screen_controller.dart';

class CreateTextField extends StatelessWidget {
  final CreateScreenController controller;
  final VoidCallback onChanged;

  const CreateTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.captionController,
      maxLines: null,
      onChanged: (val) => onChanged(),
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
}

