import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/user_avatar.dart';

enum MatchPopupAction { sendMessage, keepSwiping }

/// Full-screen celebratory overlay shown when two users like each other.
/// Returns the action the user chose so the caller can navigate.
Future<MatchPopupAction?> showMatchPopup(
  BuildContext context, {
  required User currentUser,
  required User otherUser,
  required Match match,
}) {
  return showGeneralDialog<MatchPopupAction>(
    context: context,
    barrierLabel: 'Match',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => _MatchPopup(
      currentUser: currentUser,
      otherUser: otherUser,
    ),
    transitionBuilder: (_, animation, _, child) {
      final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _MatchPopup extends StatelessWidget {
  const _MatchPopup({
    required this.currentUser,
    required this.otherUser,
  });

  final User currentUser;
  final User otherUser;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              "It's a match!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You and ${otherUser.name.split(' ').first} liked each other.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            _OverlappingAvatars(
              currentUser: currentUser,
              otherUser: otherUser,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  MatchPopupAction.sendMessage,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Send a message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                MatchPopupAction.keepSwiping,
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Keep swiping',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({
    required this.currentUser,
    required this.otherUser,
  });

  final User currentUser;
  final User otherUser;

  @override
  Widget build(BuildContext context) {
    const size = 100.0;
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _RingedAvatar(
              photoUrl: currentUser.photoUrl,
              name: currentUser.name,
              size: size,
            ),
          ),
          Positioned(
            right: 0,
            child: _RingedAvatar(
              photoUrl: otherUser.photoUrl,
              name: otherUser.name,
              size: size,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingedAvatar extends StatelessWidget {
  const _RingedAvatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });

  final String photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: UserAvatar(photoUrl: photoUrl, name: name, size: size),
    );
  }
}
