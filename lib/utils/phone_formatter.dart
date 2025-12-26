class PhoneFormatter {
  // 전화번호 포맷팅 (010-1234-5678)
  static String format(String phone) {
    // 숫자만 추출
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length <= 3) {
      return digits;
    } else if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length <= 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
    }
  }

  // 숫자만 추출
  static String extractDigits(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // 유효한 전화번호인지 확인
  static bool isValid(String phone) {
    final digits = extractDigits(phone);
    return digits.length == 11 && digits.startsWith('010');
  }
}

