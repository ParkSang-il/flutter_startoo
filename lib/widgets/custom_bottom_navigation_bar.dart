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
    final selectedColor = Theme.of(context).colorScheme.onPrimary;
    final unselectedColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
              icon: FontAwesomeIcons.houseChimney,
              isSelected: currentIndex == 0,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(0),
            ),
            _buildNavItem(
              context: context,
              icon: FontAwesomeIcons.magnifyingGlass,
              isSelected: currentIndex == 1,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(1),
            ),
            _buildNavItem(
              context: context,
              icon: FontAwesomeIcons.squarePlus,
              isSelected: currentIndex == 2,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(2),
            ),
            _buildNavItem(
              context: context,
              icon: FontAwesomeIcons.heart,
              isSelected: currentIndex == 3,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onTap(3),
            ),
            _buildNavItem(
              context: context,
              icon: FontAwesomeIcons.user,
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: FaIcon(
            icon,
            size: 22,
            color: isSelected ? selectedColor : unselectedColor,
          ),
        ),
      ),
    );
  }
}

