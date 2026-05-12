import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../chat/screens/chat_screen.dart';
import '../widgets/match_popup.dart';
import '../widgets/swipe_card.dart';
import '../widgets/user_detail_sheet.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _swiperController = CardSwiperController();
  StreamSubscription<List<User>>? _sub;

  /// Snapshot of candidates taken on first load. We don't update this on
  /// every stream emit because [CardSwiper] is keyed by [cardsCount] —
  /// changing it mid-swipe would reset/glitch the deck. Likes/passes still
  /// flow into the data service; we just don't refresh the visible deck
  /// until the user runs out.
  List<User> _deck = const [];
  bool _initialized = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = ref.read(dataServiceProvider).candidates().listen((users) {
      if (!mounted) return;
      if (!_initialized) {
        setState(() {
          _deck = users;
          _initialized = true;
          _exhausted = users.isEmpty;
        });
      }
    });
  }

  Future<void> _refreshDeck() async {
    // Take a fresh snapshot of whatever the service currently considers
    // visible. The pre-seeded mock has nothing left after they're all
    // swiped, so the result is usually empty — but the architecture is
    // ready for a real backend that keeps producing candidates.
    final users = await ref.read(dataServiceProvider).candidates().first;
    if (!mounted) return;
    setState(() {
      _deck = users;
      _exhausted = users.isEmpty;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _swiperController.dispose();
    super.dispose();
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (previousIndex >= _deck.length) return true;
    final user = _deck[previousIndex];
    final svc = ref.read(dataServiceProvider);

    switch (direction) {
      case CardSwiperDirection.right:
        final match = await svc.likeUser(user.uid);
        if (!mounted) return true;
        if (match != null) {
          final currentUser = await svc.currentUser();
          if (!mounted || currentUser == null) return true;
          final action = await showMatchPopup(
            context,
            currentUser: currentUser,
            otherUser: user,
            match: match,
          );
          if (!mounted) return true;
          if (action == MatchPopupAction.sendMessage) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(matchId: match.id, otherUser: user),
              ),
            );
          }
        }
        break;
      case CardSwiperDirection.left:
        await svc.passUser(user.uid);
        break;
      default:
        break;
    }
    return true;
  }

  void _onEnd() {
    if (!mounted) return;
    setState(() => _exhausted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: SafeArea(
        child: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : _exhausted || _deck.isEmpty
                ? _EmptyDeck(onRefresh: _refreshDeck)
                : _DeckBody(
                    deck: _deck,
                    controller: _swiperController,
                    onSwipe: _onSwipe,
                    onEnd: _onEnd,
                  ),
      ),
    );
  }
}

class _DeckBody extends StatelessWidget {
  const _DeckBody({
    required this.deck,
    required this.controller,
    required this.onSwipe,
    required this.onEnd,
  });

  final List<User> deck;
  final CardSwiperController controller;
  final CardSwiperOnSwipe onSwipe;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: deck.length,
            numberOfCardsDisplayed: deck.length >= 3 ? 3 : deck.length,
            backCardOffset: const Offset(0, 28),
            scale: 0.94,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            allowedSwipeDirection: const AllowedSwipeDirection.only(
              left: true,
              right: true,
            ),
            onSwipe: onSwipe,
            onEnd: onEnd,
            cardBuilder: (context, index, _, _) => SwipeCard(
              user: deck[index],
              onTap: () => showUserDetailSheet(context, deck[index]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.danger,
                tooltip: 'Pass',
                onTap: () =>
                    controller.swipe(CardSwiperDirection.left),
              ),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                tooltip: 'Like',
                large: true,
                onTap: () =>
                    controller.swipe(CardSwiperDirection.right),
              ),
              _ActionButton(
                icon: Icons.info_outline_rounded,
                color: AppColors.primary,
                tooltip: 'View details',
                onTap: () {
                  // Tap the card itself for details — this button is a hint.
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 68.0 : 56.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: color, size: large ? 32 : 26),
          ),
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.travel_explore_rounded,
      title: 'No one new nearby',
      subtitle: "You've seen everyone for now — check back later for new partners.",
      action: ElevatedButton.icon(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ),
    );
  }
}
