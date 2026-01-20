class ImageUrlHelper {
  static const String baseImageUrl = 'https://6n86dw2k13558.edge.naverncp.com/Q1MW6O4ec9';

  /// 이미지 URL을 전체 URL로 변환
  /// [imagePath] 상대 경로 또는 전체 URL
  /// [width] 이미지 너비 (선택사항, 피드리스트: 500, 커버이미지: 500)
  static String buildImageUrl(String? imagePath, {int? width}) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // 이미 전체 URL인 경우
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // 이미 파라미터가 있는지 확인
      if (width != null && !imagePath.contains('?')) {
        return '$imagePath?type=w&w=$width';
      }
      return imagePath;
    }

    // 기본 이미지 경로인 경우
    if (imagePath.startsWith('/default/')) {
      return '';
    }

    // 상대 경로인 경우 기본 URL 앞에 붙이기
    String fullUrl;
    if (!imagePath.startsWith('/')) {
      fullUrl = '$baseImageUrl/$imagePath';
    } else {
      fullUrl = '$baseImageUrl$imagePath';
    }

    // 너비 파라미터 추가
    if (width != null) {
      fullUrl = '$fullUrl?type=w&w=$width';
    }

    return fullUrl;
  }

  /// 피드리스트 이미지 URL 생성 (너비 500)
  static String buildFeedImageUrl(String? imagePath) {
    return buildImageUrl(imagePath, width: 500);
  }

  /// 커버 이미지 URL 생성 (너비 500)
  static String buildCoverImageUrl(String? imagePath) {
    return buildImageUrl(imagePath, width: 500);
  }

  /// 일반 이미지 URL 생성 (파라미터 없음)
  static String buildGeneralImageUrl(String? imagePath) {
    return buildImageUrl(imagePath);
  }

  /// 이미지 디테일 스크린용 URL 생성 (너비 500)
  static String buildDetailImageUrl(String? imagePath) {
    return buildImageUrl(imagePath, width: 500);
  }
}

