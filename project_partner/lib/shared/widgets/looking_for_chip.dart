import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Pill badge that visualizes a `lookingFor` category with its icon + color.
class LookingForChip extends StatelessWidget {
  const LookingForChip({super.key, required this.lookingFor, this.dense = false});

  final String lookingFor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = lookingForOptions[lookingFor] ?? lookingFor;
    final icon = lookingForIcons[lookingFor] ?? Icons.label_outline;
    final color = lookingForColors[lookingFor] ?? Colors.grey;

    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    final fontSize = dense ? 12.0 : 13.0;
    final iconSize = dense ? 14.0 : 16.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
