import 'package:flutter/material.dart';
import '../../../utils/tag_helper.dart';

// 커스텀 컨트롤러: #태그를 실시간으로 파란색으로 하이라이트
class TagHighlightController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TagHelper.buildTagHighlightTextSpan(
      text: text,
      baseStyle: style,
    );
  }
}

