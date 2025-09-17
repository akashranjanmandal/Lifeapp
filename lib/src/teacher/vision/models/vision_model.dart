import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SubjectInfo {
  final int id;
  final String title;
  final String? heading;
  final String? image;

  SubjectInfo({
    required this.id,
    required this.title,
    this.heading,
    this.image,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    String titleText = '';
    if (json['title'] != null) {
      if (json['title'] is Map) {
        titleText = json['title']['en'] ?? '';
      } else {
        String rawTitle = json['title'].toString();
        if (rawTitle.contains(':')) {
          RegExp regex = RegExp(r'[\(\{].*?:\s*(.+?)[\)\}]');
          final match = regex.firstMatch(rawTitle);
          titleText = match?.group(1) ?? rawTitle;
        } else {
          titleText = rawTitle;
        }
      }
    }

    return SubjectInfo(
      id: json['id'] ?? 0,
      title: titleText,
      heading: json['heading']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'heading': heading,
    'image': image,
  };

  @override
  String toString() => title;

  String get displayName => title;
}

class LevelInfo {
  final int id;
  final String title;
  final String description;
  final int missionPoints;
  final int quizPoints;
  final int riddlePoints;
  final int puzzlePoints;
  final int jigyasaPoints;
  final int pragyaPoints;
  int? teacher_assign_points;
  int? teacher_correct_submission_points;
  final int quizTime;
  final int riddleTime;
  final int puzzleTime;
  final int unlock;

  LevelInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.missionPoints,
    required this.quizPoints,
    required this.riddlePoints,
    required this.puzzlePoints,
    required this.jigyasaPoints,
    required this.pragyaPoints,
    this.teacher_assign_points,
    this.teacher_correct_submission_points,
    required this.quizTime,
    required this.riddleTime,
    required this.puzzleTime,
    required this.unlock,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      missionPoints: json['mission_points'] ?? 0,
      quizPoints: json['quiz_points'] ?? 0,
      riddlePoints: json['riddle_points'] ?? 0,
      teacher_assign_points: json["teacher_assign_points"] ?? 0,
      teacher_correct_submission_points: json["teacher_correct_submission_points"] ?? 0,
      puzzlePoints: json['puzzle_points'] ?? 0,
      jigyasaPoints: json['jigyasa_points'] ?? 0,
      pragyaPoints: json['pragya_points'] ?? 0,
      quizTime: json['quiz_time'] ?? 0,
      riddleTime: json['riddle_time'] ?? 0,
      puzzleTime: json['puzzle_time'] ?? 0,
      unlock: json['unlock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'mission_points': missionPoints,
    'quiz_points': quizPoints,
    'riddle_points': riddlePoints,
    'puzzle_points': puzzlePoints,
    'jigyasa_points': jigyasaPoints,
    'pragya_points': pragyaPoints,
    "teacher_assign_points": teacher_assign_points,
    "teacher_correct_submission_points": teacher_correct_submission_points,
    'quiz_time': quizTime,
    'riddle_time': riddleTime,
    'puzzle_time': puzzleTime,
    'unlock': unlock,
  };

  @override
  String toString() => title;

  String get displayName => title;
}

class ChapterInfo {
  final int id;
  final String title;

  ChapterInfo({required this.id, required this.title});

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
  };
}

class TeacherVisionVideo {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String subject; // fallback string
  final SubjectInfo? subjectInfo;
  final String? la_subject_id;
  final String? chapterId;
  final String level; // fallback string
  final LevelInfo? levelInfo;
  bool teacherAssigned;
  final List<dynamic>? studentsAssigned;
  final String? dueDate;
  final int? submittedCount;
  final int? totalAssignedStudents;

  // New fields
  final ChapterInfo? chapter;
  final int? questionsCount;
  final String? assigned_by;
  final List<dynamic>? assignments;

  TeacherVisionVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    this.chapterId,
    required this.thumbnailUrl,
    required this.subject,
    this.subjectInfo,
    required this.la_subject_id,
    required this.level,
    this.levelInfo,
    required this.teacherAssigned,
    this.studentsAssigned,
    this.dueDate,
    this.submittedCount,
    this.totalAssignedStudents,
    this.chapter,
    this.questionsCount,
    this.assigned_by,
    this.assignments,
  });

  String get subjectDisplay => subjectInfo?.displayName ?? subject;
  String get levelDisplay => levelInfo?.displayName ?? level;

  static String? getVideoIdFromUrl(String url) =>
      YoutubePlayer.convertUrlToId(url);

  static String getThumbnailUrl(String videoId, {bool highQuality = false}) {
    if (videoId.isEmpty) {
      return 'https://via.placeholder.com/320x180?text=No+Video+ID';
    }
    final quality = highQuality ? 'hqdefault' : 'mqdefault';
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  factory TeacherVisionVideo.fromJson(Map<String, dynamic> json) {
    String videoId = '';
    String thumbnail = '';

    if (json['youtubeUrl'] != null) {
      videoId = getVideoIdFromUrl(json['youtubeUrl']) ?? '';
      thumbnail = json['thumbnailUrl'] != null
          ? json['thumbnailUrl']
          : videoId.isNotEmpty
          ? getThumbnailUrl(videoId)
          : 'https://via.placeholder.com/320x180?text=No+Thumbnail';
    } else {
      thumbnail = 'https://via.placeholder.com/320x180?text=No+Video+URL';
    }

    // Parse subject
    String subjectString = '';
    SubjectInfo? subjectInfo;
    if (json['subject'] != null) {
      if (json['subject'] is Map<String, dynamic>) {
        try {
          subjectInfo = SubjectInfo.fromJson(json['subject']);
          subjectString = subjectInfo.title;
        } catch (e) {
          subjectString = json['subject'].toString();
        }
      } else {
        subjectString = json['subject'].toString();
      }
    }

    // Parse level
    String levelString = '';
    LevelInfo? levelInfo;
    if (json['level'] != null) {
      if (json['level'] is Map<String, dynamic>) {
        try {
          levelInfo = LevelInfo.fromJson(json['level']);
          levelString = levelInfo.title;
        } catch (e) {
          levelString = json['level'].toString();
        }
      } else {
        levelString = json['level'].toString();
      }
    }

    return TeacherVisionVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      thumbnailUrl: thumbnail,
      subject: subjectString,
      subjectInfo: subjectInfo,
      la_subject_id: json['la_subject_id']?.toString(),
      level: levelString,
      levelInfo: levelInfo,
      chapterId: json['chapter_id']?.toString(),
      teacherAssigned: json['teacherAssigned'] ?? false,
      studentsAssigned: json['studentsAssigned'],
      dueDate: json['dueDate']?.toString(),
      submittedCount: json['submittedCount'] as int?,
      totalAssignedStudents: json['totalAssignedStudents'] as int?,
      chapter: json['chapter'] != null ? ChapterInfo.fromJson(json['chapter']) : null,
      questionsCount: json['questionsCount'] as int?,
      assigned_by: json['assigned_by']?.toString(),
      assignments: json['assignments'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'youtubeUrl': youtubeUrl,
    'thumbnailUrl': thumbnailUrl,
    'subject': subjectInfo?.toJson() ?? subject,
    'la_subject_id': la_subject_id,
    'level': levelInfo?.toJson() ?? level,
    'teacherAssigned': teacherAssigned,
    'studentsAssigned': studentsAssigned,
    'dueDate': dueDate,
    'submittedCount': submittedCount,
    'totalAssignedStudents': totalAssignedStudents,
    'chapter': chapter?.toJson(),
    'questionsCount': questionsCount,
    'assigned_by': assigned_by,
    'assignments': assignments,
  };
}

// Pagination Classes
class PaginationLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  PaginationLinks({this.first, this.last, this.prev, this.next});

  factory PaginationLinks.fromJson(Map<String, dynamic> json) {
    return PaginationLinks(
      first: json['first'],
      last: json['last'],
      prev: json['prev'],
      next: json['next'],
    );
  }

  Map<String, dynamic> toJson() => {
    'first': first,
    'last': last,
    'prev': prev,
    'next': next,
  };
}

class MetaLink {
  final String? url;
  final String label;
  final bool active;

  MetaLink({this.url, required this.label, required this.active});

  factory MetaLink.fromJson(Map<String, dynamic> json) {
    return MetaLink(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'label': label,
    'active': active,
  };
}

class PaginationMeta {
  final int currentPage;
  final int from;
  final int lastPage;
  final List<MetaLink> links;
  final String path;
  final int perPage;
  final int to;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    var linksList = json['links'] as List;
    List<MetaLink> links =
    linksList.map((link) => MetaLink.fromJson(link)).toList();

    return PaginationMeta(
      currentPage: json['current_page'] ?? 0,
      from: json['from'] ?? 0,
      lastPage: json['last_page'] ?? 0,
      links: links,
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 0,
      to: json['to'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'from': from,
    'last_page': lastPage,
    'links': links.map((link) => link.toJson()).toList(),
    'path': path,
    'per_page': perPage,
    'to': to,
    'total': total,
  };
}

class VisionsData {
  final List<TeacherVisionVideo> data;
  final PaginationLinks links;
  final PaginationMeta meta;

  VisionsData({required this.data, required this.links, required this.meta});

  factory VisionsData.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<TeacherVisionVideo> videos =
    dataList.map((item) => TeacherVisionVideo.fromJson(item)).toList();

    return VisionsData(
      data: videos,
      links: PaginationLinks.fromJson(json['links']),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }

  Map<String, dynamic> toJson() => {
    'data': data.map((video) => video.toJson()).toList(),
    'links': links.toJson(),
    'meta': meta.toJson(),
  };
}

class TeacherVisionsResponse {
  final int status;
  final VisionsData visions;
  final String message;

  TeacherVisionsResponse({
    required this.status,
    required this.visions,
    required this.message,
  });

  factory TeacherVisionsResponse.fromJson(Map<String, dynamic> json) {
    return TeacherVisionsResponse(
      status: json['status'] ?? 0,
      visions: VisionsData.fromJson(json['data']['visions']),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'data': {'visions': visions.toJson()},
    'message': message,
  };
}
