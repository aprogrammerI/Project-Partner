import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _avatarBase = 'https://i.pravatar.cc/300?u=';

  Future<void> seedIfNeeded() async {
    final doc = await _db.collection('users').doc('u_ana').get();
    if (doc.exists) return; // Already seeded
    await seedUsers();
  }

  Future<void> seedUsers() async {
    final now = DateTime.now();

    final users = [
      User(
        uid: 'u_ana',
        email: 'ana@example.com',
        name: 'Ana Stojanovska',
        age: 21,
        photoUrl: '${_avatarBase}ana',
        bio: 'Math nerd. Looking for someone to grind Algorithms with.',
        faculty: 'FINKI',
        skills: const ['Python', 'SQL', 'Research'],
        lookingFor: 'study_buddy',
        createdAt: now.subtract(const Duration(days: 12)),
        rating: 30,
      ),
      User(
        uid: 'u_elena',
        email: 'elena@example.com',
        name: 'Elena Trajkovska',
        age: 23,
        photoUrl: '${_avatarBase}elena',
        bio: 'Final year. Need a partner for a mobile dev project.',
        faculty: 'FINKI',
        skills: const ['Flutter', 'Figma', 'UI/UX Design'],
        lookingFor: 'project_partner',
        createdAt: now.subtract(const Duration(days: 9)),
        rating: 45,
      ),
      User(
        uid: 'u_david',
        email: 'david@example.com',
        name: 'David Nikolov',
        age: 25,
        photoUrl: '${_avatarBase}david',
        bio: 'Building a fintech MVP, looking for a technical co-founder.',
        faculty: 'Economics',
        skills: const ['Business Plan', 'Finance', 'Marketing'],
        lookingFor: 'co_founder',
        createdAt: now.subtract(const Duration(days: 5)),
        rating: 60,
      ),
      User(
        uid: 'u_maja',
        email: 'maja@example.com',
        name: 'Maja Ilieva',
        age: 22,
        photoUrl: '${_avatarBase}maja',
        bio: 'Designer with too many ideas. Need a developer to build them.',
        faculty: 'Architecture',
        skills: const ['UI/UX Design', 'Figma', 'Graphic Design'],
        lookingFor: 'collaborator',
        createdAt: now.subtract(const Duration(days: 4)),
        rating: 50,
      ),
      User(
        uid: 'u_stefan',
        email: 'stefan@example.com',
        name: 'Stefan Jovanov',
        age: 24,
        photoUrl: '${_avatarBase}stefan',
        bio: 'Freelance backend dev. Looking for short gigs.',
        faculty: 'FEIT',
        skills: const ['Python', 'SQL', 'Firebase'],
        lookingFor: 'freelancer',
        createdAt: now.subtract(const Duration(days: 8)),
        rating: 25,
      ),
      User(
        uid: 'u_kristina',
        email: 'kristina@example.com',
        name: 'Kristina Mihajlova',
        age: 20,
        photoUrl: '${_avatarBase}kristina',
        bio: 'Second year. Looking for a study buddy for Databases.',
        faculty: 'FINKI',
        skills: const ['SQL', 'Java', 'Python'],
        lookingFor: 'study_buddy',
        createdAt: now.subtract(const Duration(days: 7)),
        rating: 20,
      ),
      User(
        uid: 'u_ivan',
        email: 'ivan@example.com',
        name: 'Ivan Kostov',
        age: 26,
        photoUrl: '${_avatarBase}ivan',
        bio: 'ML researcher. Open to side-project collaborations.',
        faculty: 'FEIT',
        skills: const ['Python', 'Machine Learning', 'Data Analysis'],
        lookingFor: 'collaborator',
        createdAt: now.subtract(const Duration(days: 11)),
        rating: 55,
      ),
      User(
        uid: 'u_sara',
        email: 'sara@example.com',
        name: 'Sara Petreska',
        age: 22,
        photoUrl: '${_avatarBase}sara',
        bio: 'Looking for a partner for our last-year capstone project.',
        faculty: 'FINKI',
        skills: const ['JavaScript', 'Project Management', 'Flutter'],
        lookingFor: 'project_partner',
        createdAt: now.subtract(const Duration(days: 3)),
        rating: 40,
      ),
      User(
        uid: 'u_filip',
        email: 'filip@example.com',
        name: 'Filip Andonov',
        age: 27,
        photoUrl: '${_avatarBase}filip',
        bio: 'I have an idea for a health app. Need a designer + developer.',
        faculty: 'Medicine',
        skills: const ['Research', 'Business Plan', 'Public Speaking'],
        lookingFor: 'co_founder',
        createdAt: now.subtract(const Duration(days: 2)),
        rating: 35,
      ),
      User(
        uid: 'u_nina',
        email: 'nina@example.com',
        name: 'Nina Velkova',
        age: 23,
        photoUrl: '${_avatarBase}nina',
        bio: 'Freelance illustrator, available for app icon / branding work.',
        faculty: 'Other',
        skills: const ['Graphic Design', 'Figma', 'Video Editing'],
        lookingFor: 'freelancer',
        createdAt: now.subtract(const Duration(days: 1)),
        rating: 15,
      ),
    ];

    final batch = _db.batch();
    for (final user in users) {
      final ref = _db.collection('users').doc(user.uid);
      batch.set(ref, user.toJson());
    }
    await batch.commit();
  }
}
