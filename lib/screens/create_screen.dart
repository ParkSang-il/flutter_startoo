import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/ncp_storage_service.dart';
import '../utils/snackbar_helper.dart';
import '../config/ncp_config.dart';
import 'feed/controllers/tag_highlight_controller.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // --- 2. 컨트롤러 교체 ---
  final TagHighlightController _captionController = TagHighlightController();

  final AuthService _authService = AuthService();
  final NcpStorageService _storageService = NcpStorageService();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  // 태그 추출 로직
  List<String> _extractTags(String text) {
    final RegExp hashtagRegex = RegExp(r"#([a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ가-힣\_]+)");
    // 중복 제거를 위해 Set으로 변환 후 다시 List로 반환
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)).toList());
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 에러: $e');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // --- 3. 게시글 등록 로직 수정 ---
  Future<void> _submitPost() async {
    if (_selectedImages.isEmpty) {
      SnackBarHelper.showError(context, '이미지는 최소 1개 이상 필요합니다.');
      return;
    }

    final String content = _captionController.text.trim();
    // 텍스트에서 태그 리스트 추출
    final List<String> extractedTags = _extractTags(content);

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. 이미지 업로드
      List<Map<String, dynamic>> uploadedImages = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = path.basename(file.path);

        final uploadedPath = await _storageService.uploadImage(file, fileName);

        if (uploadedPath == null) {
          if (mounted) SnackBarHelper.showError(context, '이미지 업로드에 실패했습니다.');
          setState(() { _isUploading = false; });
          return;
        }

        final fullImageUrl = '${NcpConfig.endpoint}${uploadedPath}';

        uploadedImages.add({
          'image_url': fullImageUrl,
          'image_order': i,
          'scale': 1.0,
          'offset_x': 0.0,
          'offset_y': 0.0,
        });
      }

      // 2. 포트폴리오 생성
      final now = DateTime.now();
      final workDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final title = content.isEmpty
          ? '새 포트폴리오'
          : (content.length > 50 ? '${content.substring(0, 50)}...' : content);

      final response = await _authService.createPortfolio(
        title: title,
        description: content.isEmpty ? '포트폴리오 설명' : content,
        workDate: workDate,
        price: 0,
        isPublic: true,
        images: uploadedImages,
        tags: extractedTags, // 추출된 태그 리스트를 서버로 전송
      );

      if (mounted) {
        if (response.success) {
          SnackBarHelper.showSuccess(context, '게시물이 등록되었습니다.');
          Navigator.of(context).pop();
        } else {
          SnackBarHelper.showError(context, response.message);
        }
      }
    } catch (e) {
      debugPrint('게시물 등록 에러: $e');
      if (mounted) {
        SnackBarHelper.showError(context, '게시물 등록 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftThreadLine(),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            );
                          },
                        ),
                        _buildTextField(),
                        if (_selectedImages.isNotEmpty)
                          _buildImagePreview(),
                        const SizedBox(height: 12),
                        _buildActionIcons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _isUploading ? null : () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 14,
                color: _isUploading ? Colors.grey : Colors.white,
              ),
            ),
          ),
          const Text('새 포트폴리오', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          _isUploading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
          )
              : GestureDetector(
            onTap: _selectedImages.isEmpty ? null : _submitPost,
            child: Text(
              '게시',
              style: TextStyle(
                fontSize: 14,
                color: _selectedImages.isEmpty ? Colors.blue.withOpacity(0.4) : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftThreadLine() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final profileImage = authProvider.currentUser?.profileImage;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              backgroundImage: profileImage != null && profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileImage == null || profileImage.isEmpty ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
            ),
            const SizedBox(height: 8),
            Container(width: 2, height: 100, color: Colors.grey.shade800),
            CircleAvatar(radius: 10, backgroundColor: Colors.grey.shade900),
          ],
        );
      },
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _captionController,
      maxLines: null,
      onChanged: (val) => setState(() {}),
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

  Widget _buildImagePreview() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImages[index], height: 240, width: 180, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 5, right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
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

  Widget _buildActionIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Icon(Icons.photo_library_outlined, color: Colors.grey.shade500, size: 22),
        ),
        const SizedBox(width: 20),
        Icon(Icons.camera_alt_outlined, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 20),
        Icon(Icons.mic_none, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 20),
        Icon(Icons.gif_box_outlined, color: Colors.grey.shade500, size: 22),
      ],
    );
  }
}