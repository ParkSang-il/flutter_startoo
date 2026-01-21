import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterCertificateUploadField extends StatelessWidget {
  final String label;
  final String? filePath;
  final bool isUploading;
  final VoidCallback onSelect;

  const RegisterCertificateUploadField({
    super.key,
    required this.label,
    required this.filePath,
    required this.isUploading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onSelect,
          icon: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FaIcon(
                  FontAwesomeIcons.fileArrowUp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          label: Text(
            isUploading
                ? '업로드 중...'
                : (filePath != null ? '파일 선택됨' : '파일 선택'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              shadows: [
                Shadow(
                  blurRadius: 1,
                  color: Colors.black87,
                  offset: const Offset(0.3, 0.3),
                ),
              ],
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: filePath != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
    );
  }
}

