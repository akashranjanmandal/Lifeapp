  import 'package:youtube_player_flutter/youtube_player_flutter.dart';

  /// Subject Info
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

  /// Level Info
  class LevelInfo {
    final int id;
    final String title;
    final String description;
    final int visionTextImagePoints; // new
    final int visionMcqPoints; // new
    final int missionPoints;
    final int quizPoints;
    final int riddlePoints;
    final int puzzlePoints;
    final int jigyasaPoints;
    final int pragyaPoints;
    int? teacherAssignPoints;
    int? teacherCorrectSubmissionPoints;
    final int quizTime;
    final int riddleTime;
    final int puzzleTime;
    final int unlock;

    LevelInfo({
      required this.id,
      required this.title,
      required this.description,
      required this.visionTextImagePoints,
      required this.visionMcqPoints,
      required this.missionPoints,
      required this.quizPoints,
      required this.riddlePoints,
      required this.puzzlePoints,
      required this.jigyasaPoints,
      required this.pragyaPoints,
      this.teacherAssignPoints,
      this.teacherCorrectSubmissionPoints,
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
        visionTextImagePoints: json['vision_text_image_points'] ?? 0,
        visionMcqPoints: json['vision_mcq_points'] ?? 0,
        missionPoints: json['mission_points'] ?? 0,
        quizPoints: json['quiz_points'] ?? 0,
        riddlePoints: json['riddle_points'] ?? 0,
        puzzlePoints: json['puzzle_points'] ?? 0,
        jigyasaPoints: json['jigyasa_points'] ?? 0,
        pragyaPoints: json['pragya_points'] ?? 0,
        teacherAssignPoints: json["teacher_assign_points"] ?? 0,
        teacherCorrectSubmissionPoints: json["teacher_correct_submission_points"] ?? 0,
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
      'vision_text_image_points': visionTextImagePoints,
      'vision_mcq_points': visionMcqPoints,
      'mission_points': missionPoints,
      'quiz_points': quizPoints,
      'riddle_points': riddlePoints,
      'puzzle_points': puzzlePoints,
      'jigyasa_points': jigyasaPoints,
      'pragya_points': pragyaPoints,
      "teacher_assign_points": teacherAssignPoints,
      "teacher_correct_submission_points": teacherCorrectSubmissionPoints,
      'quiz_time': quizTime,
      'riddle_time': riddleTime,
      'puzzle_time': puzzleTime,
      'unlock': unlock,
    };

    @override
    String toString() => title;

    String get displayName => title;
  }

  /// Chapter Info
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

  /// Teacher Vision Video
  class TeacherVisionVideo {
    final String id;
    final String title;
    final String description;
    final String youtubeUrl;
    final String thumbnailUrl;
    final String? status;
    final String subject;
    final SubjectInfo? subjectInfo;
    final String? laSubjectId;
    final String level;
    final LevelInfo? levelInfo;
    bool teacherAssigned;
    final int? assignedCount;
    final int? submittedCount;
    final List<ChapterInfo>? chapters;
    final int? questionsCount;
    final String? assignedBy;
    final List<dynamic>? assignments;

    TeacherVisionVideo({
      required this.id,
      required this.title,
      required this.description,
      required this.youtubeUrl,
      required this.thumbnailUrl,
      this.status,
      required this.subject,
      this.subjectInfo,
      required this.laSubjectId,
      required this.level,
      this.levelInfo,
      required this.teacherAssigned,
      this.assignedCount,
      this.submittedCount,
      this.chapters,
      this.questionsCount,
      this.assignedBy,
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
      // Chapters list
      List<ChapterInfo>? chaptersList;
      if (json['chapters'] != null) {
        chaptersList = (json['chapters'] as List)
            .map((c) => ChapterInfo.fromJson(c))
            .toList();
      }

      // Subject
      String subjectString = '';
      SubjectInfo? subjectInfo;
      if (json['subject'] != null) {
        if (json['subject'] is Map<String, dynamic>) {
          subjectInfo = SubjectInfo.fromJson(json['subject']);
          subjectString = subjectInfo.title;
        } else {
          subjectString = json['subject'].toString();
        }
      }

      // Level
      String levelString = '';
      LevelInfo? levelInfo;
      if (json['level'] != null) {
        if (json['level'] is Map<String, dynamic>) {
          levelInfo = LevelInfo.fromJson(json['level']);
          levelString = levelInfo.title;
        } else {
          levelString = json['level'].toString();
        }
      }

      // Thumbnail
      String thumbnail = json['thumbnailUrl']?.toString() ??
          (getVideoIdFromUrl(json['youtubeUrl']?.toString() ?? '') != null
              ? getThumbnailUrl(getVideoIdFromUrl(json['youtubeUrl']!)!)
              : 'https://via.placeholder.com/320x180?text=No+Thumbnail');

      return TeacherVisionVideo(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Video',
        description: json['description']?.toString() ?? '',
        youtubeUrl: json['youtubeUrl']?.toString() ?? '',
        thumbnailUrl: thumbnail,
        status: json['status']?.toString(),
        subject: subjectString,
        subjectInfo: subjectInfo,
        laSubjectId: json['la_subject_id']?.toString(),
        level: levelString,
        levelInfo: levelInfo,
        teacherAssigned: json['teacherAssigned'] ?? false,
        assignedCount: json['assigned_count'] as int?,
        submittedCount: json['submitted_count'] as int?,
        chapters: chaptersList,
        questionsCount: json['questionsCount'] as int?,
        assignedBy: json['assigned_by']?.toString(),
        assignments: json['assignments'] as List<dynamic>?,
      );
    }

    Map<String, dynamic> toJson() => {
      'id': id,
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'subject': subjectInfo?.toJson() ?? subject,
      'la_subject_id': laSubjectId,
      'level': levelInfo?.toJson() ?? level,
      'teacherAssigned': teacherAssigned,
      'assigned_count': assignedCount,
      'submitted_count': submittedCount,
      'chapters': chapters?.map((c) => c.toJson()).toList(),
      'questionsCount': questionsCount,
      'assigned_by': assignedBy,
      'assignments': assignments,
    };
  }

  /// Pagination Links
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

  /// Meta Link
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

  /// Pagination Meta
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

  /// Visions Data
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

  /// Teacher Visions Response
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
