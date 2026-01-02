import 'package:flutter/material.dart';

enum SnackBarType {
  error,
  success,
  info,
}

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    required String message,
    required SnackBarType type,
    IconData? icon,
    Color? backgroundColor,
    Duration? duration,
  }) : super(
          content: Row(
            children: [
              Icon(
                icon ?? _getDefaultIcon(type),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor ?? _getDefaultColor(type),
          behavior: SnackBarBehavior.floating, // Floating 스타일
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 둥근 모서리
          ),
          margin: const EdgeInsets.all(16), // Floating일 때 여백
          duration: duration ?? _getDefaultDuration(type),
          elevation: 4,
          // 애니메이션 설정 (기본적으로 SnackBar는 애니메이션이 내장되어 있음)
        );

  // 타입에 따른 기본 아이콘 반환
  static IconData _getDefaultIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.info:
        return Icons.info_outline;
    }
  }

  // 타입에 따른 기본 색상 반환
  static Color _getDefaultColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return Colors.red;
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.info:
        return Colors.blue;
    }
  }

  // 타입에 따른 기본 지속 시간 반환
  static Duration _getDefaultDuration(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return const Duration(seconds: 3);
      case SnackBarType.success:
        return const Duration(seconds: 2);
      case SnackBarType.info:
        return const Duration(seconds: 3);
    }
  }
}

