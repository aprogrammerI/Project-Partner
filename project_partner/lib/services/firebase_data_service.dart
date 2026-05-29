import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'data_service.dart';

class FirebaseDataService implements DataService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  @override
  Future<User?> currentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await getUserById(firebaseUser.uid);
  }

  @override
  Stream<User?> currentUserChanges() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _db
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return User.fromJson(doc.data()!);
      });
    });
  }

  @override
  Future<User> register({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = User(
      uid: cred.user!.uid,
      email: email,
      name: '',
      age: 0,
      photoUrl: '',
      bio: '',
      faculty: '',
      skills: const [],
      lookingFor: '',
      createdAt: DateTime.now(),
      rating: 0,
      consecutivePasses: 0,
    );
    await _db.collection('users').doc(user.uid).set(user.toJson());
    return user;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(_auth.currentUser!.uid).update({
      'lastActiveAt': DateTime.now().toIso8601String(),
    });
    return (await currentUser())!;
  }

  @override
  Future<void> logout() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  @override
  Future<User> updateProfile(User user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
    return user;
  }

  @override
  Future<User?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data()!);
  }

  @override
  Future<String> uploadProfilePhoto(File file) => throw UnimplementedError();

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  @override
  Stream<List<User>> candidates() async* {
    final uid = _auth.currentUser!.uid;
    final me = await getUserById(uid);
    if (me == null) return;

    final snapshot = await _db.collection('users').get();
    final allUsers = snapshot.docs
        .map((doc) => User.fromJson(doc.data()))
        .where((u) => u.uid != uid)
        .toList();

    final likesSnap = await _db.collection('likes')
        .where('from', isEqualTo: uid).get();
    final likedUids = likesSnap.docs.map((d) => d['to'] as String).toSet();

    final passesSnap = await _db.collection('passes')
        .where('from', isEqualTo: uid).get();

    // TODO: change back to 10 days before release
    final expiryTime = DateTime.now().subtract(const Duration(minutes: 5));
    final whoLikedSnap0 = await _db.collection('likes')
        .where('to', isEqualTo: uid).get();
    final whoLikedMe0 = whoLikedSnap0.docs.map((d) => d['from'] as String).toSet();
    final activePassUids = passesSnap.docs
        .where((d) => DateTime.parse(d['createdAt']).isAfter(expiryTime))
        .map((d) => d['to'] as String)
        .where((passedUid) => !whoLikedMe0.contains(passedUid))
        .toSet();

    // Filter out already liked/passed users
    final eligible = allUsers
        .where((u) => !likedUids.contains(u.uid))
        .where((u) => !activePassUids.contains(u.uid))
        .toList();

    final whoLikedMe = whoLikedMe0;

    int score(User u) {
      final liked = whoLikedMe.contains(u.uid) ? 1 : 0;
      final skills = u.skills.where((s) => me.skills.contains(s)).length;
      final inactiveCutoff = DateTime.now().subtract(const Duration(days: 10));
      final rating = u.lastActiveAt.isBefore(inactiveCutoff) ? u.rating - 10 : u.rating;
      return liked * 10000 + skills * 100 + rating;
    }

    // Same category first, then others — both sorted by priority score
    final sameCategory = eligible.where((u) => u.lookingFor == me.lookingFor).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));

    final otherCategory = eligible.where((u) => u.lookingFor != me.lookingFor).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    yield [...sameCategory, ...otherCategory];
  }

  @override
  Future<Match?> likeUser(String targetUid) async {
    final uid = _auth.currentUser!.uid;
    
    await _db.collection('likes').doc('${uid}_$targetUid').set({
      'from': uid,
      'to': targetUid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // +5 rating for the target
    await _db.collection('users').doc(targetUid).update({
      'rating': FieldValue.increment(5),
      'consecutivePasses': 0,
    });

    // Check for mutual like
    final mutual = await _db.collection('likes').doc('${targetUid}_$uid').get();
    if (!mutual.exists) return null;

    // Mutual like — create match
    final matchId = '${uid}_$targetUid';
    final now = DateTime.now();
    await _db.collection('matches').doc(matchId).set({
      'userIds': [uid, targetUid],
      'createdAt': now.toIso8601String(),
      'lastMessage': '',
      'lastMessageAt': now.toIso8601String(),
    });

    // +10 rating for both on match
    await _db.collection('users').doc(uid).update({'rating': FieldValue.increment(10)});
    await _db.collection('users').doc(targetUid).update({'rating': FieldValue.increment(10)});

    // Auto first message so the chat is never empty on match
    await _db.collection('matches').doc(matchId).collection('messages').add({
      'matchId': matchId,
      'senderId': 'system',
      'text': "You matched! Say hello 👋",
      'createdAt': now.toIso8601String(),
    });
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': "You matched! Say hello 👋",
      'lastMessageAt': now.toIso8601String(),
    });

    final matchDoc = await _db.collection('matches').doc(matchId).get();
    return Match.fromJson({...matchDoc.data()!, 'id': matchId});
  }

  @override
  Future<void> passUser(String targetUid) async {
    final uid = _auth.currentUser!.uid;

    // Write the pass with createdAt for 10-day expiry logic in candidates()
    await _db.collection('passes').doc('${uid}_$targetUid').set({
      'from': uid,
      'to': targetUid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Update consecutivePasses on target
    final targetDoc = await _db.collection('users').doc(targetUid).get();
    final target = User.fromJson(targetDoc.data()!);
    final newPasses = target.consecutivePasses + 1;

    if (newPasses >= 3) {
      // -1 rating and reset counter
      await _db.collection('users').doc(targetUid).update({
        'rating': FieldValue.increment(-1),
        'consecutivePasses': 0,
      });
    } else {
      await _db.collection('users').doc(targetUid).update({
        'consecutivePasses': newPasses,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Matches
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Match>> matches() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Match.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Message>> messages(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Message.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<void> sendMessage({required String matchId, required String text}) async {
    final uid = _auth.currentUser!.uid;
    final now = DateTime.now();

    // Check if this is the first message — if so, +5 rating for sender
    final existing = await _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('users').doc(uid).update({'rating': FieldValue.increment(5)});
    }

    // Add message
    await _db.collection('matches').doc(matchId).collection('messages').add({
      'matchId': matchId,
      'senderId': uid,
      'text': text,
      'createdAt': now.toIso8601String(),
    });

    // Update parent match
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': text,
      'lastMessageAt': now.toIso8601String(),
    });
  }
}
