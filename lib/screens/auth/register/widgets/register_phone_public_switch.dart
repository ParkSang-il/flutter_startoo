import 'package:flutter/material.dart';
import '../controllers/register_screen_controller.dart';

class RegisterPhonePublicSwitch extends StatelessWidget {
  final RegisterScreenController controller;
  final VoidCallback onChanged;

  const RegisterPhonePublicSwitch({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '휴대폰번호공개',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Switch(
          value: controller.contactPhonePublic,
          onChanged: (value) {
            controller.contactPhonePublic = value;
            onChanged();
          },
        ),
      ],
    );
  }
}

