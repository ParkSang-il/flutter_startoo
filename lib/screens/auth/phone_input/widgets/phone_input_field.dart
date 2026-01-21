import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/phone_formatter.dart';
import '../utils/phone_input_formatter.dart';
import '../controllers/phone_input_controller.dart';

class PhoneInputField extends StatelessWidget {
  final PhoneInputController controller;
  final VoidCallback onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
        PhoneInputFormatter(),
      ],
      cursorColor: Theme.of(context).colorScheme.onPrimary,
      decoration: InputDecoration(
        labelText: '휴대폰 번호',
        hintText: '010-1234-5678',
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onPrimary,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '휴대폰 번호를 입력해주세요';
        }
        final digits = PhoneFormatter.extractDigits(value);
        if (!PhoneFormatter.isValid(digits)) {
          return '올바른 휴대폰 번호를 입력해주세요';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}

