import 'package:flutter/material.dart';
import '../widgets/custom_snackbar.dart';

class SnackBarHelper {
  // 에러 SnackBar 표시
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar(
        message: message,
        type: SnackBarType.error,
      ),
    );
  }

  // 성공 SnackBar 표시
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar(
        message: message,
        type: SnackBarType.success,
      ),
    );
  }

  // 정보 SnackBar 표시
  static void showInfo(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar(
        message: message,
        type: SnackBarType.info,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

