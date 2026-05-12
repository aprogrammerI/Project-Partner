import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    required this.showTimestamp,
  });

  final Message message;
  final bool isSent;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final radius = Radius.circular(18);
    final tightRadius = Radius.circular(4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: isSent ? radius : tightRadius,
                  bottomRight: isSent ? tightRadius : radius,
                ),
                border: isSent
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isSent ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final isToday = now.year == time.year &&
      now.month == time.month &&
      now.day == time.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = yesterday.year == time.year &&
      yesterday.month == time.month &&
      yesterday.day == time.day;

  if (isToday) return DateFormat.Hm().format(time);
  if (isYesterday) return 'Yesterday ${DateFormat.Hm().format(time)}';
  if (now.difference(time).inDays < 7) {
    return DateFormat('EEE HH:mm').format(time);
  }
  return DateFormat('d MMM, HH:mm').format(time);
}
