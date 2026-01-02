import 'package:flutter/material.dart';

class AppBarContent extends StatelessWidget {
  const AppBarContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Instagram',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          Row(
            children: const [
              Icon(Icons.add_box_outlined, size: 26),
              SizedBox(width: 16),
              Icon(Icons.favorite_border, size: 26),
              SizedBox(width: 16),
              Icon(Icons.send_outlined, size: 26),
            ],
          ),
        ],
      ),
    );
  }
}
