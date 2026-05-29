/// Application user profile.
///
/// Shape is shared between [MockDataService] (Part A) and the future
/// FirebaseDataService (Person 2). Keep [toJson] / [fromJson] in sync
/// with the Firestore document layout.
class User {
  final String uid;
  final String email;
  final String name;
  final int age;
  final String photoUrl;
  final String bio;
  final String faculty;
  final List<String> skills;
  final String lookingFor;
  final DateTime createdAt;
  final int rating;
  final DateTime lastActiveAt;
  final int consecutivePasses;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.bio,
    required this.faculty,
    required this.skills,
    required this.lookingFor,
    required this.createdAt,
    this.rating = 0,
    this.consecutivePasses = 0,
    DateTime? lastActiveAt,
  }) : lastActiveAt = lastActiveAt ?? DateTime.now();

  User copyWith({
    String? uid,
    String? email,
    String? name,
    int? age,
    String? photoUrl,
    String? bio,
    String? faculty,
    List<String>? skills,
    String? lookingFor,
    DateTime? createdAt,
    int? rating,
    DateTime? lastActiveAt,
    int? consecutivePasses,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      faculty: faculty ?? this.faculty,
      skills: skills ?? this.skills,
      lookingFor: lookingFor ?? this.lookingFor,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'age': age,
        'photoUrl': photoUrl,
        'bio': bio,
        'faculty': faculty,
        'skills': skills,
        'lookingFor': lookingFor,
        'createdAt': createdAt.toIso8601String(),
        'rating': rating,
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'consecutivePasses': consecutivePasses,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String,
        age: (json['age'] as num).toInt(),
        photoUrl: json['photoUrl'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        faculty: json['faculty'] as String? ?? '',
        skills: (json['skills'] as List?)?.cast<String>() ?? const [],
        lookingFor: json['lookingFor'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String)
            : DateTime.now(),
        consecutivePasses: (json['consecutivePasses'] as num?)?.toInt() ?? 0,
      );
}
