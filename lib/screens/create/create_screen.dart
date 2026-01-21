import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'controllers/create_screen_controller.dart';
import 'widgets/create_header.dart';
import 'widgets/create_left_thread_line.dart';
import 'widgets/create_text_field.dart';
import 'widgets/create_media_preview.dart';
import 'widgets/create_action_icons.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  late final CreateScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickMedia() async {
    await _controller.pickMedia(context, _setState);
  }

  Future<void> _submitPost() async {
    await _controller.submitPost(context, _setState);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        // 키보드 외 영역 터치 시 키보드 숨김
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: screenHeight * 0.92,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CreateHeader(
              controller: _controller,
              onSubmit: _submitPost,
            ),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CreateLeftThreadLine(),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              );
                            },
                          ),
                          CreateTextField(
                            controller: _controller,
                            onChanged: _setState,
                          ),
                          if (_controller.mediaItems.isNotEmpty)
                            CreateMediaPreview(
                              controller: _controller,
                              setState: _setState,
                            ),
                          const SizedBox(height: 12),
                          CreateActionIcons(
                            controller: _controller,
                            onPickMedia: _pickMedia,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

