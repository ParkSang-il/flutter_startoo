import 'package:flutter/material.dart';

class TagHelper {
  // 태그를 인식하는 정규식 (한글, 영문, 숫자, 언더바 포함)
  static final RegExp hashtagRegex = RegExp(r"(#([a-zA-Z0-9ㄱ-ㅎㅏ-ㅣ가-힣\_]+))");

  // 텍스트에서 태그를 하이라이트한 TextSpan 생성
  static TextSpan buildTagHighlightTextSpan({
    required String text,
    TextStyle? baseStyle,
    Color? tagColor,
  }) {
    final List<InlineSpan> children = [];

    text.splitMapJoin(
      hashtagRegex,
      onMatch: (Match match) {
        children.add(TextSpan(
          text: match.group(0),
          style: baseStyle?.copyWith(
            color: tagColor ?? Colors.blueAccent,
          ),
        ));
        return "";
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: baseStyle));
        return "";
      },
    );

    return TextSpan(style: baseStyle, children: children);
  }
}

