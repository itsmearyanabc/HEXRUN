class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int totalHexesCaptured;
  final int totalDistanceM;
  final int totalRuns;
  final int currentStreak;
  final int rank;
  final String color;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.totalHexesCaptured = 0,
    this.totalDistanceM = 0,
    this.totalRuns = 0,
    this.currentStreak = 0,
    this.rank = 0,
    this.color = '#1A73E8',
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String? ?? '',
      totalHexesCaptured: json['totalHexesCaptured'] as int? ?? 0,
      totalDistanceM: json['totalDistanceM'] as int? ?? 0,
      totalRuns: json['totalRuns'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      color: json['color'] as String? ?? '#1A73E8',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalHexesCaptured': totalHexesCaptured,
      'totalDistanceM': totalDistanceM,
      'totalRuns': totalRuns,
      'currentStreak': currentStreak,
      'rank': rank,
      'color': color,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}