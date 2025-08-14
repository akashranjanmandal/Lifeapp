import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VisionListModel {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String? subjectName;
  final String status;
  final bool teacherAssigned;
  final bool isCompleted;
  final bool isSkipped;
  final bool isPending;
  final String? levelId;
  final VisionSubject? subject;
  final int? visionTextImagePoints;

  /// New field for total count from meta
  final int? total;

  VisionListModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.status,
    this.subjectName,
    required this.teacherAssigned,
    required this.isCompleted,
    required this.isSkipped,
    required this.isPending,
    this.levelId,
    this.subject,
    this.visionTextImagePoints,
    this.total,
  });

  factory VisionListModel.fromJson(Map<String, dynamic> json, {int? total}) {
    String videoId = '';
    String thumbnail = '';

    final statusStr = (json['status']?.toString() ?? '').toLowerCase();

    if (json.containsKey('youtubeUrl') && json['youtubeUrl'] != null) {
      videoId = getVideoIdFromUrl(json['youtubeUrl'] ?? '') ?? '';
      thumbnail = json['thumbnailUrl'] != null
          ? json['thumbnailUrl']
          : videoId.isNotEmpty
          ? getThumbnailUrl(videoId)
          : 'https://via.placeholder.com/320x180?text=No+Thumbnail';
    } else {
      thumbnail = 'https://via.placeholder.com/320x180?text=No+Video+URL';
    }

    String? levelId;
    int? visionPoints;

    if (json.containsKey('level') && json['level'] != null) {
      final level = json['level'];
      if (level is Map<String, dynamic>) {
        levelId = level['id']?.toString();
        visionPoints = level['vision_text_image_points'];
      }
    } else {
      levelId = json['levelId']?.toString() ?? json['level_id']?.toString();
    }

    return VisionListModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      thumbnailUrl: thumbnail,
      status: json['status']?.toString() ?? 'start',
      subjectName: json['subject']?['title']?['en'] ?? '',
      teacherAssigned: json['teacherAssigned'] == true,
      isCompleted: statusStr == 'completed',
      isSkipped: statusStr == 'skipped',
      isPending: statusStr == 'pending',
      levelId: levelId,
      visionTextImagePoints: visionPoints,
      total: total, // ✅ store total here
    );
  }

  static String? getVideoIdFromUrl(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  static String getThumbnailUrl(String videoId, {bool highQuality = false}) {
    if (videoId.isEmpty) {
      return 'https://via.placeholder.com/320x180?text=No+Video+ID';
    }
    String quality = highQuality ? 'hqdefault' : 'mqdefault';
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'teacherAssigned': teacherAssigned,
      'total': total,
    };
  }
}
class VisionSubject {
  final String id;
  final Map<String, dynamic> title;

  VisionSubject({
    required this.id,
    required this.title,
  });

  factory VisionSubject.fromJson(Map<String, dynamic> json) {
    return VisionSubject(
      id: json['id'].toString(),
      title: json['title'] ?? {},

    );
  }

  String get name => title['en'] ?? 'Unknown';
}

class VisionListResponse {
  final int total;
  final List<VisionListModel> visions;

  VisionListResponse({
    required this.total,
    required this.visions,
  });

  factory VisionListResponse.fromJson(Map<String, dynamic> json) {
    final visionsData = json['visions'] ?? {};
    final dataList = visionsData['data'] as List<dynamic>? ?? [];
    final meta = visionsData['meta'] ?? {};
    final totalCount = meta['total'] ?? 0;

    return VisionListResponse(
      total: totalCount,
      visions: dataList.map((e) => VisionListModel.fromJson(e)).toList(),
    );
  }
}
