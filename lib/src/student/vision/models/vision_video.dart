import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VisionVideo {
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

  VisionVideo({
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
  });

  factory VisionVideo.fromJson(Map<String, dynamic> json) {
    String videoId = '';
    String thumbnail = '';

    final statusStr = (json['status']?.toString() ?? '').toLowerCase();

    if (json.containsKey('youtubeUrl') && json['youtubeUrl'] != null) {
      videoId = getVideoIdFromUrl(json['youtubeUrl'] ?? '') ?? '';
      thumbnail = json.containsKey('thumbnailUrl') && json['thumbnailUrl'] != null
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
        if (level.containsKey('id')) {
          levelId = level['id'].toString();
        }
        if (level.containsKey('vision_text_image_points')) {
          visionPoints = level['vision_text_image_points'];
        }
      }
    } else {
      levelId = json['levelId']?.toString() ?? json['level_id']?.toString();
    }

    return VisionVideo(
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
    };
  }

  VisionVideo copyWith({
    String? id,
    String? title,
    String? description,
    String? youtubeUrl,
    String? thumbnailUrl,
    String? status,
    bool? teacherAssigned,
  }) {
    return VisionVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      teacherAssigned: teacherAssigned ?? this.teacherAssigned,
      isCompleted: isCompleted,
      isPending: isPending,
      isSkipped: isSkipped,
    );
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

class VisionVideoResponse {
  final List<VisionVideo> videos;
  final int currentPage;
  final int totalPages;
  final int totalVideos;
  final bool hasNextPage;
  final int perPage;

  VisionVideoResponse({
    required this.videos,
    required this.currentPage,
    required this.totalPages,
    required this.totalVideos,
    required this.hasNextPage,
    required this.perPage,
  });

  factory VisionVideoResponse.fromJson(Map<String, dynamic> json) {
    // -------- locate the list node (cover common API shapes) --------
    dynamic listNode;

    // data.visions.data
    if (json['data'] is Map &&
        (json['data'] as Map)['visions'] is Map &&
        ((json['data'] as Map)['visions'] as Map)['data'] is List) {
      listNode = ((json['data'] as Map)['visions'] as Map)['data'];
    }
    // data.data
    else if (json['data'] is Map && (json['data'] as Map)['data'] is List) {
      listNode = (json['data'] as Map)['data'];
    }
    // data (flat list)
    else if (json['data'] is List) {
      listNode = json['data'];
    }
    // visions.data
    else if (json['visions'] is Map && (json['visions'] as Map)['data'] is List) {
      listNode = (json['visions'] as Map)['data'];
    }
    // visions (flat)
    else if (json['visions'] is List) {
      listNode = json['visions'];
    }
    // videos (flat)
    else if (json['videos'] is List) {
      listNode = json['videos'];
    } else {
      listNode = const <dynamic>[];
    }

    // -------- strongly-typed list --------
    final List<VisionVideo> videos = (listNode is List)
        ? listNode
        .whereType<Map<String, dynamic>>()
        .map((m) => VisionVideo.fromJson(m))
        .toList()
        : <VisionVideo>[];

    // -------- read pagination meta (multiple possible locations) --------
    Map<String, dynamic>? meta;

    // data.visions.meta
    if (json['data'] is Map &&
        (json['data'] as Map)['visions'] is Map &&
        ((json['data'] as Map)['visions'] as Map)['meta'] is Map) {
      meta = ((json['data'] as Map)['visions'] as Map)['meta'] as Map<String, dynamic>;
    }

    // data.meta
    meta ??= (json['data'] is Map && (json['data'] as Map)['meta'] is Map)
        ? ((json['data'] as Map)['meta'] as Map<String, dynamic>)
        : null;

    // visions.meta
    meta ??= (json['visions'] is Map && (json['visions'] as Map)['meta'] is Map)
        ? ((json['visions'] as Map)['meta'] as Map<String, dynamic>)
        : null;

    // top-level meta
    meta ??= (json['meta'] is Map) ? (json['meta'] as Map<String, dynamic>) : null;

    int _asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      if (v is num) return v.toInt();
      return fallback;
    }

    int currentPage = 1;
    int totalPages = 1;
    int total = videos.length;
    int perPage = 10;

    if (meta != null) {
      currentPage = _asInt(meta['current_page'], currentPage);
      totalPages  = _asInt(meta['last_page'] ?? meta['total_pages'], totalPages);
      total       = _asInt(meta['total'] ?? meta['total_videos'], total);
      perPage     = _asInt(meta['per_page'], perPage);
    } else {
      // sensible fallback if no meta: infer perPage from list length
      perPage = videos.length == 0 ? 10 : videos.length;
      currentPage = 1;
      totalPages = 1;
      total = videos.length;
    }

    final bool hasNextPage = currentPage < totalPages;

    return VisionVideoResponse(
      videos: videos,
      currentPage: currentPage,
      totalPages: totalPages,
      totalVideos: total,
      hasNextPage: hasNextPage,
      perPage: perPage,
    );
  }
}
