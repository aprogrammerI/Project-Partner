import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'data_service.dart';

/// In-memory implementation of [DataService] for UI development.
///
/// Seeds 10 candidate users, marks two of them as "will match back" so the
/// match popup can be triggered during demos, and pre-creates two matches
/// (each with a couple of messages) so the Matches and Chat tabs are not
/// empty on first launch.
class MockDataService implements DataService {
  MockDataService() {
    _seed();
  }

  final _uuid = const Uuid();
  final _random = Random();

  /// Canned replies used by the fake auto-responder to make chat demos feel
  /// alive. Picked at random; one is sent ~1.8s after every user message.
  static const _cannedReplies = <String>[
    'Sounds great!',
    'Tell me more.',
    "Yeah, that works for me.",
    'Cool, when are you free?',
    "Awesome, count me in.",
    "I'd love to hear more about your idea.",
    "Let's grab coffee and chat.",
    'Send me your details.',
    'Same here, looking forward to it.',
    'Nice, I can help with that.',
  ];

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------
  User? _currentUser;
  final List<User> _users = [];
  final List<Match> _matches = [];
  final Map<String, List<Message>> _messagesByMatch = {};

  /// uids that will instantly produce a match when the current user likes
  /// them. Lets the demo trigger the "It's a match!" popup reliably.
  final Set<String> _willMatchBack = {};

  /// uids the current user has already swiped on (either direction).
  final Set<String> _swipedUids = {};

  // Broadcast controllers so the UI can listen to changes.
  final _currentUserController = StreamController<User?>.broadcast();
  final _candidatesController = StreamController<List<User>>.broadcast();
  final _matchesController = StreamController<List<Match>>.broadcast();
  final Map<String, StreamController<List<Message>>> _messageControllers = {};

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------
  void _seed() {
    final now = DateTime.now();

    // Start signed out so the demo always opens at the splash screen.
    // Login / register will populate _currentUser as uid 'me' so the seeded
    // matches (which reference 'me') become the new user's matches.

    _users.addAll([
      User(
        uid: 'u_ana',
        email: 'ana@example.com',
        name: 'Ana Stojanovska',
        age: 21,
        photoUrl: 'https://i.pravatar.cc/300?u=ana',
        bio: 'Math nerd. Looking for someone to grind Algorithms with.',
        faculty: 'FINKI',
        skills: const ['Algorithms', 'Python', 'LaTeX'],
        lookingFor: 'study_buddy',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      User(
        uid: 'u_elena',
        email: 'elena@example.com',
        name: 'Elena Trajkovska',
        age: 23,
        photoUrl: 'https://i.pravatar.cc/300?u=elena',
        bio: 'Final year. Need a partner for a mobile dev project.',
        faculty: 'FINKI',
        skills: const ['Flutter', 'UI/UX', 'Figma'],
        lookingFor: 'project_partner',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      User(
        uid: 'u_david',
        email: 'david@example.com',
        name: 'David Nikolov',
        age: 25,
        photoUrl: 'https://i.pravatar.cc/300?u=david',
        bio: 'Building a fintech MVP, looking for a technical co-founder.',
        faculty: 'Economics',
        skills: const ['Business', 'Finance', 'Pitch'],
        lookingFor: 'co_founder',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      User(
        uid: 'u_maja',
        email: 'maja@example.com',
        name: 'Maja Ilieva',
        age: 22,
        photoUrl: 'https://i.pravatar.cc/300?u=maja',
        bio: 'Designer with too many ideas. Need a developer to build them.',
        faculty: 'Architecture',
        skills: const ['UI/UX', 'Branding', 'Illustration'],
        lookingFor: 'collaborator',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      User(
        uid: 'u_stefan',
        email: 'stefan@example.com',
        name: 'Stefan Jovanov',
        age: 24,
        photoUrl: 'https://i.pravatar.cc/300?u=stefan',
        bio: 'Freelance backend dev. Looking for short gigs.',
        faculty: 'FEIT',
        skills: const ['Node.js', 'PostgreSQL', 'AWS'],
        lookingFor: 'freelancer',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      User(
        uid: 'u_kristina',
        email: 'kristina@example.com',
        name: 'Kristina Mihajlova',
        age: 20,
        photoUrl: 'https://i.pravatar.cc/300?u=kristina',
        bio: 'Second year. Looking for a study buddy for Databases.',
        faculty: 'FINKI',
        skills: const ['SQL', 'Java', 'Teamwork'],
        lookingFor: 'study_buddy',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      User(
        uid: 'u_ivan',
        email: 'ivan@example.com',
        name: 'Ivan Kostov',
        age: 26,
        photoUrl: 'https://i.pravatar.cc/300?u=ivan',
        bio: 'ML researcher. Open to side-project collaborations.',
        faculty: 'FEIT',
        skills: const ['Python', 'PyTorch', 'Research'],
        lookingFor: 'collaborator',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      User(
        uid: 'u_sara',
        email: 'sara@example.com',
        name: 'Sara Petreska',
        age: 22,
        photoUrl: 'https://i.pravatar.cc/300?u=sara',
        bio: 'Looking for a partner for our last-year capstone project.',
        faculty: 'FINKI',
        skills: const ['React', 'Node.js', 'PM'],
        lookingFor: 'project_partner',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      User(
        uid: 'u_filip',
        email: 'filip@example.com',
        name: 'Filip Andonov',
        age: 27,
        photoUrl: 'https://i.pravatar.cc/300?u=filip',
        bio: 'I have an idea for a health app. Need a designer + developer.',
        faculty: 'Medicine',
        skills: const ['Healthcare', 'Strategy'],
        lookingFor: 'co_founder',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      User(
        uid: 'u_nina',
        email: 'nina@example.com',
        name: 'Nina Velkova',
        age: 23,
        photoUrl: 'https://i.pravatar.cc/300?u=nina',
        bio: 'Freelance illustrator, available for app icon / branding work.',
        faculty: 'Other',
        skills: const ['Illustration', 'Logos', 'Procreate'],
        lookingFor: 'freelancer',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Trigger the match popup reliably on these two users during demos.
    _willMatchBack.addAll(['u_elena', 'u_maja']);

    // Pre-existing matches so the Matches tab is not empty on first run.
    final m1 = Match(
      id: 'match_1',
      userIds: ['me', 'u_ana'],
      createdAt: now.subtract(const Duration(days: 2)),
      lastMessage: 'Sounds good, see you tomorrow at the library!',
      lastMessageAt: now.subtract(const Duration(hours: 3)),
    );
    final m2 = Match(
      id: 'match_2',
      userIds: ['me', 'u_david'],
      createdAt: now.subtract(const Duration(days: 1)),
      lastMessage: 'I sent you the deck — let me know what you think.',
      lastMessageAt: now.subtract(const Duration(hours: 20)),
    );
    _matches.addAll([m2, m1]);

    _messagesByMatch[m1.id] = [
      Message(
        id: _uuid.v4(),
        matchId: m1.id,
        senderId: 'u_ana',
        text: 'Hey! Saw we both matched on Study buddy.',
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      Message(
        id: _uuid.v4(),
        matchId: m1.id,
        senderId: 'me',
        text: 'Nice! Are you free tomorrow to go over Algorithms?',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Message(
        id: _uuid.v4(),
        matchId: m1.id,
        senderId: 'u_ana',
        text: 'Sounds good, see you tomorrow at the library!',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
    _messagesByMatch[m2.id] = [
      Message(
        id: _uuid.v4(),
        matchId: m2.id,
        senderId: 'me',
        text: 'Hi David, your fintech idea looks interesting.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Message(
        id: _uuid.v4(),
        matchId: m2.id,
        senderId: 'u_david',
        text: 'I sent you the deck — let me know what you think.',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
    ];
  }

  List<User> _visibleCandidates() {
    final currentUid = _currentUser?.uid;
    return _users
        .where((u) => u.uid != currentUid && !_swipedUids.contains(u.uid))
        .toList(growable: false);
  }

  void _emitCandidates() => _candidatesController.add(_visibleCandidates());
  void _emitMatches() =>
      _matchesController.add(List.unmodifiable(_matches));

  void _emitMessages(String matchId) {
    final controller = _messageControllers[matchId];
    if (controller != null) {
      controller.add(List.unmodifiable(_messagesByMatch[matchId] ?? const []));
    }
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  @override
  Future<User?> currentUser() async => _currentUser;

  @override
  Stream<User?> currentUserChanges() async* {
    yield _currentUser;
    yield* _currentUserController.stream;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final fresh = User(
      uid: 'me',
      email: email,
      name: '',
      age: 0,
      photoUrl: '',
      bio: '',
      faculty: '',
      skills: const [],
      lookingFor: 'study_buddy',
      createdAt: DateTime.now(),
    );
    _currentUser = fresh;
    _swipedUids.clear();
    _currentUserController.add(fresh);
    _emitCandidates();
    return fresh;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user = User(
      uid: 'me',
      email: email,
      name: 'Marko Petrov',
      age: 22,
      photoUrl: 'https://i.pravatar.cc/300?u=me',
      bio: 'CS student looking for a co-founder for a study app idea.',
      faculty: 'FINKI',
      skills: const ['Flutter', 'Firebase', 'Product'],
      lookingFor: 'co_founder',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _currentUser = user;
    _currentUserController.add(user);
    _emitCandidates();
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _swipedUids.clear();
    _currentUserController.add(null);
    _emitCandidates();
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------
  @override
  Future<User> updateProfile(User user) async {
    _currentUser = user;
    _currentUserController.add(user);
    return user;
  }

  @override
  Future<String> uploadProfilePhoto(File file) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return file.path;
  }

  @override
  Future<User?> getUserById(String uid) async {
    if (uid == _currentUser?.uid) return _currentUser;
    for (final u in _users) {
      if (u.uid == uid) return u;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------
  @override
  Stream<List<User>> candidates() async* {
    yield _visibleCandidates();
    yield* _candidatesController.stream;
  }

  @override
  Future<Match?> likeUser(String targetUid) async {
    _swipedUids.add(targetUid);
    _emitCandidates();

    if (!_willMatchBack.contains(targetUid)) return null;
    if (_currentUser == null) return null;

    final match = Match(
      id: 'match_${_uuid.v4()}',
      userIds: [_currentUser!.uid, targetUid],
      createdAt: DateTime.now(),
    );
    _matches.insert(0, match);
    _messagesByMatch[match.id] = [];
    _emitMatches();
    return match;
  }

  @override
  Future<void> passUser(String targetUid) async {
    _swipedUids.add(targetUid);
    _emitCandidates();
  }

  // ---------------------------------------------------------------------------
  // Matches
  // ---------------------------------------------------------------------------
  @override
  Stream<List<Match>> matches() async* {
    yield List.unmodifiable(_matches);
    yield* _matchesController.stream;
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------
  @override
  Stream<List<Message>> messages(String matchId) async* {
    final controller = _messageControllers.putIfAbsent(
      matchId,
      () => StreamController<List<Message>>.broadcast(),
    );
    yield List.unmodifiable(_messagesByMatch[matchId] ?? const []);
    yield* controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String text,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final msg = Message(
      id: _uuid.v4(),
      matchId: matchId,
      senderId: user.uid,
      text: text,
      createdAt: DateTime.now(),
    );
    final bucket = _messagesByMatch.putIfAbsent(matchId, () => []);
    bucket.add(msg);
    _emitMessages(matchId);

    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx != -1) {
      _matches[idx] = _matches[idx].copyWith(
        lastMessage: text,
        lastMessageAt: msg.createdAt,
      );
      _matches.sort(
        (a, b) => (b.lastMessageAt ?? b.createdAt)
            .compareTo(a.lastMessageAt ?? a.createdAt),
      );
      _emitMatches();
    }

    _scheduleAutoReply(matchId);
  }

  /// Demo-only: simulate the matched user replying ~1.8s later so the chat
  /// feels alive without a backend. Will be removed when [DataService] is
  /// swapped to FirebaseDataService.
  void _scheduleAutoReply(String matchId) {
    final match = _matches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => Match(id: '', userIds: const [], createdAt: DateTime.now()),
    );
    if (match.id.isEmpty) return;
    final me = _currentUser?.uid;
    if (me == null) return;
    final otherUid = match.userIds.firstWhere(
      (uid) => uid != me,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return;

    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      // Bail if the match was removed or the user signed out in the meantime.
      if (_currentUser == null) return;
      if (!_matches.any((m) => m.id == matchId)) return;

      final reply = Message(
        id: _uuid.v4(),
        matchId: matchId,
        senderId: otherUid,
        text: _cannedReplies[_random.nextInt(_cannedReplies.length)],
        createdAt: DateTime.now(),
      );
      final bucket = _messagesByMatch.putIfAbsent(matchId, () => []);
      bucket.add(reply);
      _emitMessages(matchId);

      final i = _matches.indexWhere((m) => m.id == matchId);
      if (i != -1) {
        _matches[i] = _matches[i].copyWith(
          lastMessage: reply.text,
          lastMessageAt: reply.createdAt,
        );
        _matches.sort(
          (a, b) => (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt),
        );
        _emitMatches();
      }
    });
  }
}
