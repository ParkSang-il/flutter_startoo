import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_bar_content.dart';

class InstagramAppBar extends StatelessWidget {
  final bool visible;
  final double topPadding;

  const InstagramAppBar({
    super.key,
    required this.visible,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      top: visible ? 0 : -56 - topPadding,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 56 + topPadding,
            padding: EdgeInsets.only(top: topPadding),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withOpacity(0.92),
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  color: Colors.black.withOpacity(0.08),
                ),
              ],
            ),
            child: const AppBarContent(),
          ),
        ),
      ),
    );
  }
}
