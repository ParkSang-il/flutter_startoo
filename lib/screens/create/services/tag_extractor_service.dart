// 태그 추출 로직
class TagExtractorService {
  // 텍스트에서 해시태그 추출
  static List<String> extractTags(String text) {
    final RegExp hashtagRegex = RegExp(r"#([a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ가-힣\_]+)");
    // 중복 제거를 위해 Set으로 변환 후 다시 List로 반환
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(1)!)
        .toSet()
        .toList();
  }
}

