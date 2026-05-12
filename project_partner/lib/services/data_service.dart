import 'dart:io';

import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// The contract every data backend must satisfy.
///
/// Part A ships [MockDataService] which implements this against in-memory
/// lists. In a later phase, Person 2 will ship FirebaseDataService that
/// implements the same interface against Firestore / Firebase Auth /
/// Firebase Storage. UI code MUST depend on this abstraction only.
abstract class DataService {
  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// The currently logged-in user, or null if signed out.
  Future<User?> currentUser();

  /// Live stream of the current user. Emits null on logout.
  Stream<User?> currentUserChanges();

  /// Create a new account. Returns a partially-filled [User] that the caller
  /// is expected to complete via [updateProfile] (profile setup screen).
  Future<User> register({required String email, required String password});

  /// Sign in an existing user.
  Future<User> login({required String email, required String password});

  /// Sign out the current user.
  Future<void> logout();

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Persist (or replace) a user document.
  Future<User> updateProfile(User user);

  /// Upload a profile photo. Returns the URL to store on the user document.
  /// The mock implementation just returns the local file path; Firebase will
  /// upload to Storage and return the download URL.
  Future<String> uploadProfilePhoto(File file);

  /// Look up any user by uid (used to show the "other" side of a match).
  Future<User?> getUserById(String uid);

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  /// Stream of users to show in the swipe stack. Excludes the current user
  /// and anyone they've already swiped on.
  Stream<List<User>> candidates();

  /// Record a "like". May immediately produce a [Match] if the target user
  /// already liked the current user; otherwise returns null.
  Future<Match?> likeUser(String targetUid);

  /// Record a "pass" (left swipe). Does not produce matches.
  Future<void> passUser(String targetUid);

  // ---------------------------------------------------------------------------
  // Matches
  // ---------------------------------------------------------------------------

  /// Stream of the current user's matches, most-recently-active first.
  Stream<List<Match>> matches();

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  /// Stream of messages inside a match, oldest first.
  Stream<List<Message>> messages(String matchId);

  /// Send a text message and update the match's lastMessage / lastMessageAt.
  Future<void> sendMessage({required String matchId, required String text});
}
