import 'package:flutter/material.dart';

class FeedItem extends StatelessWidget {
  final int index;

  const FeedItem({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          'Feed Item $index',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
