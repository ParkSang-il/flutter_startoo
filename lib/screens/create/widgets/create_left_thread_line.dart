import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CreateLeftThreadLine extends StatelessWidget {
  const CreateLeftThreadLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final profileImage = authProvider.currentUser?.profileImage;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? const FaIcon(
                      FontAwesomeIcons.user,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Container(width: 2, height: 100, color: Colors.grey.shade800),
            CircleAvatar(radius: 10, backgroundColor: Colors.grey.shade900),
          ],
        );
      },
    );
  }
}

