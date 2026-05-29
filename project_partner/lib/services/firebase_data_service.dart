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
  // Discovery - TODO
  // ---------------------------------------------------------------------------

  @override
  Stream<List<User>> candidates() => Stream.value([]);

  @override
  Future<Match?> likeUser(String targetUid) async => null;

  @override
  Future<void> passUser(String targetUid) async {}

  // ---------------------------------------------------------------------------
  // Matches — TODO
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Match>> matches() => Stream.value([]);

  // ---------------------------------------------------------------------------
  // Chat — TODO
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Message>> messages(String matchId) => Stream.value([]);

  @override
  Future<void> sendMessage({required String matchId, required String text}) async {}
}
