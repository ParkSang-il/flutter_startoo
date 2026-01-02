import 'package:flutter/widgets.dart';

class FeedScrollController {
  bool showAppBar = true;
  double _lastOffset = 0;
  final VoidCallback onUpdate;

  FeedScrollController({required this.onUpdate});

  bool handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;

      if (offset > _lastOffset + 2) {
        if (showAppBar) {
          showAppBar = false;
          onUpdate();
        }
      } else if (offset < _lastOffset - 2) {
        if (!showAppBar) {
          showAppBar = true;
          onUpdate();
        }
      }

      _lastOffset = offset;
    }

    if (notification is ScrollEndNotification) {
      if (!showAppBar) {
        showAppBar = true;
        onUpdate();
      }
    }

    return false;
  }
}
