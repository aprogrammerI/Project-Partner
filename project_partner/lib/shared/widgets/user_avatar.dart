import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Circular avatar that handles three photo sources:
/// - empty string -> initials fallback
/// - http(s) / blob URL -> CachedNetworkImage
/// - local file path -> Image.file (mobile/desktop only)
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 48,
  });

  final String photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final initials = _initials(name);

    Widget child;
    if (photoUrl.isEmpty) {
      child = _InitialsCircle(
        initials: initials,
        size: size,
      );
    } else if (photoUrl.startsWith('http') || photoUrl.startsWith('blob:')) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) =>
              _InitialsCircle(initials: initials, size: size),
          errorWidget: (_, _, _) =>
              _InitialsCircle(initials: initials, size: size),
        ),
      );
    } else if (!kIsWeb) {
      child = ClipOval(
        child: Image.file(
          File(photoUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialsCircle(initials: initials, size: size),
        ),
      );
    } else {
      child = _InitialsCircle(initials: initials, size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
