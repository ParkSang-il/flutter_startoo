import 'package:flutter/material.dart';

class FeedItem extends StatelessWidget {
  final int index;

  const FeedItem({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        'Post $index',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
