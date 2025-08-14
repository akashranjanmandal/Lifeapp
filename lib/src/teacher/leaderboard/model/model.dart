class LeaderboardEntry {
  final int rank;
  final int? teacherId;
  final String name;
  final String schoolName;
  final int totalEarnedCoins;
  final String? profileImage;

  LeaderboardEntry({
    required this.rank,
    this.teacherId,
    required this.name,
    required this.schoolName,
    required this.totalEarnedCoins,
    this.profileImage,
  });

  factory LeaderboardEntry.fromTeacherJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: parseToInt(json['rank']),
      teacherId: parseToInt(json['teacher_id']),
      name: json['name'] ?? '',
      schoolName: json['school_name'] ?? '',
      totalEarnedCoins: parseToInt(json['total_earned_coins']),
      profileImage: json['image_path'],
    );
  }

  factory LeaderboardEntry.fromSchoolJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: parseToInt(json['rank']),
      teacherId: null,
      name: json['school_name'] ?? '',
      schoolName: '',
      totalEarnedCoins: parseToInt(json['total_coins'] ?? json['s_score']),
      profileImage: null,
    );
  }
}

/// Helper to safely convert anything to int
int parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
