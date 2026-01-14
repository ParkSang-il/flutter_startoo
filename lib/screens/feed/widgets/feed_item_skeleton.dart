import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// 스켈레톤 피드 아이템 위젯 생성
class FeedItemSkeleton extends StatelessWidget {
  const FeedItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측 라인 스켈레톤
            Column(
              children: [
                _shimmer(CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade800),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // 우측 콘텐츠 스켈레톤
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _shimmer(Container(width: 80, height: 14, color: Colors.white)),
                      const SizedBox(width: 8),
                      _shimmer(Container(width: 40, height: 12, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _shimmer(Container(width: double.infinity, height: 14, color: Colors.white)),
                  const SizedBox(height: 6),
                  _shimmer(Container(width: 200, height: 14, color: Colors.white)),
                  const SizedBox(height: 12),
                  _shimmer(
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(4, (index) =>
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: _shimmer(const Icon(Icons.circle, size: 22)),
                        ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: child,
    );
  }
}