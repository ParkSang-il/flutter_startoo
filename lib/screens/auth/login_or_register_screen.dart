import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/custom_text_button.dart';
import 'phone_input/phone_input_screen.dart';
import 'terms_agreement/terms_agreement_screen.dart';

class LoginOrRegisterScreen extends StatelessWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 (겹치는 느낌)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Image.asset('assets/images/startoo_logo.png'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '당신의 타투를 스타투하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              CustomTextButton(
                text: 'LOGIN',
                fontSize: 15,
                textColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const PhoneInputScreen(isRegister: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomTextButton(
                text: 'JOIN',
                fontSize: 15,
                textColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsAgreementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30), // bottomNavigationBar와의 간격
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.copyright,
                color: Colors.grey.shade700, size: 15),
            const SizedBox(width: 2),
            Text('STARTOO',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
