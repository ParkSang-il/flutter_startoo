import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? refreshIcon;
  final Color? iconColor;
  final Color? backgroundColor;
  final ScrollController? scrollController;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshIcon,
    this.iconColor,
    this.backgroundColor,
    this.scrollController,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  double _dragOffset = 0.0;
  late AnimationController _controller;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController = widget.scrollController;
    _scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CustomRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      _scrollController = widget.scrollController;
      _scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController?.removeListener(_onScroll);
    // scrollController는 외부에서 관리하므로 dispose하지 않음
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController != null && !_isRefreshing) {
      final offset = _scrollController!.offset;
      if (offset < 0) {
        setState(() {
          _dragOffset = -offset;
        });
        const double triggerOffset = 100.0;
        const double minVisibleOffset = 40.0;
        if (_dragOffset > minVisibleOffset) {
          _controller.value = ((_dragOffset - minVisibleOffset) / (triggerOffset - minVisibleOffset)).clamp(0.0, 1.0);
        } else {
          _controller.value = 0.0;
        }
      } else {
        if (_dragOffset > 0) {
          setState(() {
            _dragOffset = 0.0;
          });
          _controller.animateTo(0.0);
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } catch (e) {
      debugPrint('리프레시 에러: $e');
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _dragOffset = 0.0;
      });
      _controller.reset();
      
      // 스크롤 위치를 0으로 되돌림
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double refreshThreshold = 80.0; // 리프레시 시작 임계값
    const double minVisibleOffset = 40.0; // 아이콘이 처음 나타나는 최소 오프셋

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels < 0 && !_isRefreshing) {
            setState(() {
              _dragOffset = -metrics.pixels;
            });
            const double triggerOffset = 100.0;
            const double minVisibleOffset = 40.0;
            // 최소 오프셋 이상일 때만 애니메이션 진행
            if (_dragOffset > minVisibleOffset) {
              _controller.value = ((_dragOffset - minVisibleOffset) / (triggerOffset - minVisibleOffset)).clamp(0.0, 1.0);
            } else {
              _controller.value = 0.0;
            }
          }
        } else if (notification is ScrollEndNotification) {
          if (_dragOffset > refreshThreshold && !_isRefreshing) {
            debugPrint('리프레시 시작: _dragOffset = $_dragOffset');
            _handleRefresh();
          } else {
            setState(() {
              _dragOffset = 0.0;
            });
            _controller.animateTo(0.0);
          }
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragOffset > minVisibleOffset || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                color: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: _isRefreshing
                      ? widget.refreshIcon ??
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.iconColor ?? Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                      : Transform.rotate(
                          angle: _controller.value * 2 * 3.14159,
                          child: widget.refreshIcon ??
                              FaIcon(
                                FontAwesomeIcons.arrowsRotate,
                                color: widget.iconColor ?? Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

