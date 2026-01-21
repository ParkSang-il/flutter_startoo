import 'dart:io';

// 미디어 타입을 구분하기 위한 클래스
class MediaItem {
  final File file;
  final bool isVideo;
  
  MediaItem({required this.file, required this.isVideo});
}

