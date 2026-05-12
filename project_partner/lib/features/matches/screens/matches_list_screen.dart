import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';
import '../../../services/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../chat/screens/chat_screen.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(_matchesStreamProvider);
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final currentUid = currentUserAsync.valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (matches) {
            if (matches.isEmpty) {
              return const EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No matches yet',
                subtitle: 'Head back to Discover and start swiping!',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 88,
                endIndent: 16,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchTile(
                  match: match,
                  currentUid: currentUid,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match, required this.currentUid});

  final Match match;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = match.otherUserId(currentUid);
    final otherUserAsync = ref.watch(_otherUserProvider(otherUid));

    return otherUserAsync.when(
      loading: () => const ListTile(
        leading: SizedBox(width: 48, height: 48),
        title: SizedBox.shrink(),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();
        final preview = match.lastMessage ?? 'Say hi to start the conversation';
        final hasMessage = match.lastMessage != null;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: UserAvatar(
            photoUrl: otherUser.photoUrl,
            name: otherUser.name,
            size: 56,
          ),
          title: Text(
            otherUser.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasMessage
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontStyle:
                    hasMessage ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          trailing: match.lastMessageAt != null
              ? Text(
                  _formatTimestamp(match.lastMessageAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                matchId: match.id,
                otherUser: otherUser,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatTimestamp(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('d MMM').format(time);
}

final _matchesStreamProvider = StreamProvider.autoDispose<List<Match>>((ref) {
  return ref.watch(dataServiceProvider).matches();
});

final _otherUserProvider =
    FutureProvider.family.autoDispose<User?, String>((ref, uid) {
  return ref.watch(dataServiceProvider).getUserById(uid);
});
