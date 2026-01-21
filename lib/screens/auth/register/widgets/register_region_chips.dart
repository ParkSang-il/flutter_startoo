import 'package:flutter/material.dart';
import '../controllers/register_screen_controller.dart';
import '../model/register_constants.dart';

class RegisterRegionChips extends StatelessWidget {
  final RegisterScreenController controller;
  final VoidCallback onChanged;

  const RegisterRegionChips({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '작업가능지역',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RegisterConstants.regionOptions.map((region) {
            final isSelected = controller.availableRegions.contains(region);
            return FilterChip(
              label: Text(region),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.background,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black87,
                    offset: const Offset(0.3, 0.3),
                  ),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  controller.availableRegions.add(region);
                } else {
                  controller.availableRegions.remove(region);
                }
                onChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

