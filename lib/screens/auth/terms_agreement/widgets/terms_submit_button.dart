import 'package:flutter/material.dart';
import '../controllers/terms_agreement_controller.dart';

class TermsSubmitButton extends StatelessWidget {
  final TermsAgreementController controller;
  final VoidCallback onPressed;

  const TermsSubmitButton({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.canProceed ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey.shade600,
        ),
        child: const Text(
          '다음',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                blurRadius: 1,
                color: Colors.black87,
                offset: Offset(0.3, 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

