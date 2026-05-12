import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/looking_for_chip.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Bottom sheet showing the full profile of a user from the swipe stack.
Future<void> showUserDetailSheet(BuildContext context, User user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _UserDetailSheet(user: user),
  );
}

class _UserDetailSheet extends StatelessWidget {
  const _UserDetailSheet({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: UserAvatar(
                photoUrl: user.photoUrl,
                name: user.name,
                size: 140,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${user.name}${user.age > 0 ? ', ${user.age}' : ''}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: LookingForChip(lookingFor: user.lookingFor)),
            const SizedBox(height: 24),
            if (user.faculty.isNotEmpty)
              _Row(icon: Icons.school_outlined, text: user.faculty),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel(label: 'About'),
              const SizedBox(height: 6),
              Text(
                user.bio,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (user.skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionLabel(label: 'Skills'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final s in user.skills) Chip(label: Text(s))],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
