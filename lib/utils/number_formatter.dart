class NumberFormatter {
  // 숫자를 1.0k 형식으로 변환
  static String formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      if (k % 1 == 0) {
        return '${k.toInt()}k';
      } else {
        return '${k.toStringAsFixed(1)}k';
      }
    } else {
      final m = count / 1000000;
      if (m % 1 == 0) {
        return '${m.toInt()}M';
      } else {
        return '${m.toStringAsFixed(1)}M';
      }
    }
  }
}

