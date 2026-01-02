import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;

  // ✅ 배경 그라데이션/색상 추가
  final Gradient? backgroundGradient;
  final Color? backgroundColor;

  // ✅ 모서리/테두리 옵션(선택)
  final BorderSide? borderSide;

  // ✅ 아이콘 추가
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final double iconSpacing;
  final bool iconRight; // false: 왼쪽, true: 오른쪽

  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.backgroundGradient,
    this.backgroundColor,
    this.borderSide,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.iconSpacing = 8,
    this.iconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;

    final textWidget = Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.bold,
        letterSpacing: 0.5,
        color: effectiveTextColor,
        shadows: const [
          Shadow(offset: Offset(1, 1), color: Colors.black54, blurRadius: 2),
        ],
      ),
    );

    Widget child;

    if (icon != null) {
      final iconWidget = Icon(
        icon,
        size: iconSize ?? 30,
        color: iconColor ?? effectiveTextColor,
      );

      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          SizedBox(width: iconSpacing),
          Expanded(
            child: Center(child: textWidget),
          )
        ],
      );
    } else {
      child = textWidget;
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.all(Radius.circular(6)),
          color: backgroundGradient == null
              ? (backgroundColor ?? Colors.transparent)
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              side: borderSide ?? BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

