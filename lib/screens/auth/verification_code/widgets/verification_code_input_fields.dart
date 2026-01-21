import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/verification_code_controller.dart';

class VerificationCodeInputFields extends StatelessWidget {
  final VerificationCodeController controller;
  final String phone;
  final bool isRegister;
  final VoidCallback setState;

  const VerificationCodeInputFields({
    super.key,
    required this.controller,
    required this.phone,
    required this.isRegister,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.center,
            cursorHeight: 25,
            cursorColor: Theme.of(context).colorScheme.onPrimary,
            controller: controller.controllers[index],
            focusNode: controller.focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onPrimary,
                  width: 2,
                ),
              ),
              filled: false,
            ),
            onChanged: (value) => controller.onCodeChanged(
              index,
              value,
              phone,
              isRegister,
              context,
              setState,
            ),
          ),
        );
      }),
    );
  }
}

