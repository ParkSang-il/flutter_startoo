import 'package:flutter/material.dart';
import '../controllers/terms_agreement_controller.dart';

class TermsAgreeAllCheckbox extends StatelessWidget {
  final TermsAgreementController controller;
  final VoidCallback onChanged;

  const TermsAgreeAllCheckbox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: controller.agreeAll
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: controller.agreeAll,
            onChanged: (value) {
              controller.onAgreeAllChanged(value, onChanged);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '전체 동의',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

