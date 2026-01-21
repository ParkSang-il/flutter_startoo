import 'package:flutter/material.dart';
import '../controllers/register_screen_controller.dart';
import '../model/register_constants.dart';

class RegisterStyleChips extends StatelessWidget {
  final RegisterScreenController controller;
  final VoidCallback onChanged;

  const RegisterStyleChips({
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
          '작업가능한스타일',
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
          children: RegisterConstants.styleOptions.map((style) {
            final isSelected = controller.mainStyles.contains(style);
            return FilterChip(
              label: Text(style),
              selected: isSelected,
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
                  controller.mainStyles.add(style);
                } else {
                  controller.mainStyles.remove(style);
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

