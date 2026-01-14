import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme
        .of(context)
        .colorScheme
        .onPrimary;
    final unselectedColor = Theme
        .of(context)
        .colorScheme
        .onSurface;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: (FontAwesomeIcons.houseChimney),
              isSelected: currentIndex == 0,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(0),
            ),
            _buildNavItem(
              context: context,
              icon: (FontAwesomeIcons.magnifyingGlass),
              isSelected: currentIndex == 1,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(1),
            ),
            _buildNavItem(
              context: context,
              icon: FontAwesomeIcons.plus,
              // 또는 FontAwesomeIcons.squarePlus
              isSelected: currentIndex == 2,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              isCustom: true,
              // 여기서 커스텀 활성화!
              onTap: () => onTap(2),
            ),
            _buildNavItem(
              context: context,
              icon: (FontAwesomeIcons.heart),
              isSelected: currentIndex == 3,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(3),
            ),
            _buildNavItem(
              context: context,
              icon: (FontAwesomeIcons.user),
              isSelected: currentIndex == 4,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required VoidCallback onTap,
    bool isCustom = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: isCustom
              ? _buildTikTokStyleIcon(isSelected) // 1. Stack으로 그린 커스텀 아이콘
              : FaIcon(icon, size: 24, color: isSelected ? selectedColor : unselectedColor),
        ),
      ),
    );
  }

  Widget _buildTikTokStyleIcon(bool isSelected) {
    return SizedBox(
      width: 45,
      height: 30,
      child: Stack(
        children: [
          // [레이어 1] 왼쪽 파란색 배경 (살짝 왼쪽으로 어긋남)
          Positioned(
            left: 0,
            child: Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF2AFADF), // 틱톡 특유의 청록색
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // [레이어 2] 오른쪽 빨간색 배경 (살짝 오른쪽으로 어긋남)
          Positioned(
            right: 0,
            child: Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFE2C55), // 틱톡 특유의 레드
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // [레이어 3] 중앙 흰색(또는 테마색) 배경 및 아이콘
          Center(
            child: Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}