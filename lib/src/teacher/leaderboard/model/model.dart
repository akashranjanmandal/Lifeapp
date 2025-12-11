class LeaderboardEntry {
  final int rank;
  final int? teacherId;
  final int? schoolId;
  final String name;
  final String schoolName;
  final int totalEarnedCoins;
  final String? profileImage;
  final double tScore;   // For teacher leaderboard
  final double sScore;   // For school leaderboard
  final int assignTaskCoins;
  final int correctSubmissionCoins;
  final int maxPossibleCoins;
  final int studentCoins;
  final int teacherCoins;
  final int maxStudentCoins;
  final int maxTeacherCoins;

  LeaderboardEntry({
    required this.rank,
    this.teacherId,
    this.schoolId,
    required this.name,
    required this.schoolName,
    required this.totalEarnedCoins,
    this.profileImage,
    required this.tScore,
    required this.sScore,
    required this.assignTaskCoins,
    required this.correctSubmissionCoins,
    required this.maxPossibleCoins,
    required this.studentCoins,
    required this.teacherCoins,
    required this.maxStudentCoins,
    required this.maxTeacherCoins,
  });

  factory LeaderboardEntry.fromTeacherJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: parseToInt(json['rank']),
      teacherId: parseToInt(json['teacher_id']),
      name: json['name'] ?? '',
      schoolName: '', // Will be added separately if needed
      totalEarnedCoins: parseToInt(json['total_earned_coins']),
      profileImage: json['image_path'],
      tScore: parseToDouble(json['t_score']),
      assignTaskCoins: parseToInt(json['assign_task_coins']),
      correctSubmissionCoins: parseToInt(json['correct_submission_coins']),
      maxPossibleCoins: parseToInt(json['max_possible_coins']),
      sScore: 0,
      studentCoins: 0,
      teacherCoins: 0,
      maxStudentCoins: 0,
      maxTeacherCoins: 0,
    );
  }

  factory LeaderboardEntry.fromSchoolJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: parseToInt(json['rank']),
      schoolId: parseToInt(json['school_id']),
      name: json['school_name'] ?? '',
      schoolName: json['school_name'] ?? '',
      totalEarnedCoins: parseToInt(json['total_coins']),
      profileImage: null,
      sScore: parseToDouble(json['s_score']),
      studentCoins: parseToInt(json['student_coins']),
      teacherCoins: parseToInt(json['teacher_coins']),
      maxStudentCoins: parseToInt(json['max_student_coins']),
      maxTeacherCoins: parseToInt(json['max_teacher_coins']),
      tScore: 0,
      assignTaskCoins: 0,
      correctSubmissionCoins: 0,
      maxPossibleCoins: 0,
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

/// Helper to safely convert anything to double
double parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}