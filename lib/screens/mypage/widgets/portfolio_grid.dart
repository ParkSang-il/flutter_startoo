import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum PortfolioGridType {
  image,
  video,
}

class PortfolioGrid extends StatelessWidget {
  final PortfolioGridType type;

  const PortfolioGrid({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: type == PortfolioGridType.image ? 20 : 10,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3열
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: type == PortfolioGridType.video ? 0.7 : 1.0, // 릴스는 세로가 더 김
      ),
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey.shade800,
          child: FaIcon(
            type == PortfolioGridType.video
                ? FontAwesomeIcons.circlePlay
                : FontAwesomeIcons.image,
            color: Colors.grey.shade600,
          ),
        );
      },
    );
  }
}

