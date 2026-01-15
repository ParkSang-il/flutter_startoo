import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: (user?.profileImage == null || (user!.profileImage?.isEmpty ?? true))
                    ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                    : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(context, "게시물", "0"),
                    _buildStatColumn(context, "팔로워", "0"),
                    _buildStatColumn(context, "팔로잉", "0"),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.username ?? '사용자 이름',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '여기에 자기소개글이 들어갑니다.\n플러터로 만드는 인스타그램 클론!',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  child: Text(
                    '프로필 편집',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  child: Text(
                    '프로필 공유',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

