class Match {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Match({
    required this.id,
    required this.userIds,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  /// Returns the uid of the other participant given the current user's uid.
  String otherUserId(String currentUid) =>
      userIds.firstWhere((id) => id != currentUid, orElse: () => '');

  Match copyWith({
    String? id,
    List<String>? userIds,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return Match(
      id: id ?? this.id,
      userIds: userIds ?? this.userIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userIds': userIds,
        'createdAt': createdAt.toIso8601String(),
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        userIds: (json['userIds'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastMessage: json['lastMessage'] as String?,
        lastMessageAt: json['lastMessageAt'] == null
            ? null
            : DateTime.parse(json['lastMessageAt'] as String),
      );
}
