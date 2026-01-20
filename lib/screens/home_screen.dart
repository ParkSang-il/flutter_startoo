import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import 'auth/login_or_register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starttoo'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginOrRegisterScreen(),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Center(
        child: authProvider.isAuthenticated
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (authProvider.currentUser?.profileImage != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        authProvider.currentUser!.profileImage!,
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 50,
                      child: FaIcon(FontAwesomeIcons.user, size: 50),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    '안녕하세요, ${authProvider.currentUser?.nickname ?? authProvider.currentUser?.username ?? "사용자"}님!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '회원 유형: ${authProvider.currentUser?.userType == 2 ? "사업자" : "일반 회원"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '로그인이 필요합니다',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginOrRegisterScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('로그인'),
                  ),
                ],
              ),
      ),
    );
  }
}

