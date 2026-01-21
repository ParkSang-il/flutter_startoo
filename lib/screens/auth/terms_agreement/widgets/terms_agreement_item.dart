import 'package:flutter/material.dart';

class TermsAgreementItem extends StatelessWidget {
  final String title;
  final bool isRequired;
  final bool isAgreed;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onViewDetail;

  const TermsAgreementItem({
    super.key,
    required this.title,
    required this.isRequired,
    required this.isAgreed,
    required this.onChanged,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: isAgreed,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          isRequired ? '(필수)' : '(선택)',
          style: TextStyle(
            fontSize: 14,
            color: isRequired
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onViewDetail,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '보기',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

