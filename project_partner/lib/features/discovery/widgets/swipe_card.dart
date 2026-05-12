import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/looking_for_chip.dart';
import '../../../shared/widgets/user_avatar.dart';

class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CardBackground(user: user),
              const _BottomGradient(),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LookingForChip(lookingFor: user.lookingFor, dense: true),
                    const SizedBox(height: 12),
                    Text(
                      '${user.name}${user.age > 0 ? ', ${user.age}' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (user.faculty.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.faculty,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (user.skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in user.skills.take(3))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isEmpty) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: UserAvatar(
          photoUrl: '',
          name: user.name,
          size: 160,
        ),
      );
    }
    final isNetwork = user.photoUrl.startsWith('http') ||
        user.photoUrl.startsWith('blob:');
    if (!isNetwork) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: UserAvatar(
          photoUrl: user.photoUrl,
          name: user.name,
          size: 160,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: user.photoUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        color: AppColors.primary.withValues(alpha: 0.10),
      ),
      errorWidget: (_, _, _) => Container(
        color: AppColors.primary.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: UserAvatar(
          photoUrl: '',
          name: user.name,
          size: 160,
        ),
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.78),
          ],
          stops: const [0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}
