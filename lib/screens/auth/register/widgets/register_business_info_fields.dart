import 'package:flutter/material.dart';
import '../controllers/register_screen_controller.dart';
import 'register_input_decoration.dart';

class RegisterBusinessInfoFields extends StatelessWidget {
  final RegisterScreenController controller;

  const RegisterBusinessInfoFields({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상호
        TextFormField(
          controller: controller.businessNameController,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          decoration: RegisterInputDecoration.buildInputDecoration(
            context,
            '상호',
            '상호명을 입력하세요',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '상호를 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // 사업자등록번호
        TextFormField(
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          controller: controller.businessNumberController,
          decoration: RegisterInputDecoration.buildInputDecoration(
            context,
            '사업자등록번호',
            '123-45-67890',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '사업자등록번호를 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // 주소
        TextFormField(
          controller: controller.addressController,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          decoration: RegisterInputDecoration.buildInputDecoration(
            context,
            '주소',
            '전북특별자치도 전주시 덕진구 백제대로 567',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '주소를 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // 상세주소
        TextFormField(
          controller: controller.addressDetailController,
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          decoration: RegisterInputDecoration.buildInputDecoration(
            context,
            '상세주소 (선택)',
            '4층 401호',
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

