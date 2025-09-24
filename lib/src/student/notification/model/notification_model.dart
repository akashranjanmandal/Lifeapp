import 'dart:convert';
import 'package:flutter/foundation.dart';

class NotificationModel {
  final int? status;
  final List<NotificationData>? data;
  final String? message;

  NotificationModel({
    this.status,
    this.data,
    this.message,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      status: json['status'] as int?,
      data: (json['data'] as List?)
          ?.map((e) {
        debugPrint('NotificationModel.fromJson: notification raw data: $e');
        return NotificationData.fromJson(e as Map<String, dynamic>);
      })
          .toList(),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'data': data?.map((e) => e.toJson()).toList(),
    'message': message,
  };
}

class NotificationData {
  final String? id;
  final String? type;
  final String? createdAt; // <-- add this back
  final NotificationInner1Data data;

  NotificationData({
    this.id,
    this.type,
    this.createdAt,
    required this.data,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    NotificationInner1Data parsedData;

    final rawData = json['data'];
    if (rawData != null && rawData is Map<String, dynamic>) {
      parsedData = NotificationInner1Data.fromJson(rawData);
    } else if (rawData != null && rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          parsedData = NotificationInner1Data.fromJson(decoded);
        } else {
          parsedData = NotificationInner1Data(title: '', message: '', data: ActionData(action: 0));
        }
      } catch (_) {
        parsedData = NotificationInner1Data(title: '', message: '', data: ActionData(action: 0));
      }
    } else {
      parsedData = NotificationInner1Data(title: '', message: '', data: ActionData(action: 0));
    }

    return NotificationData(
      id: json['id']?.toString(),
      type: json['type']?.toString(),
      createdAt: json['created_at']?.toString(), // <-- parse this
      data: parsedData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'created_at': createdAt,
    'data': data.toJson(),
  };
}

class NotificationInner1Data {
  final String title;
  final String message;
  final ActionData data;

  NotificationInner1Data({
    required this.title,
    required this.message,
    required this.data,
  });

  factory NotificationInner1Data.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> actionMap = {};

    final raw = json['data'];
    if (raw != null && raw is Map<String, dynamic>) {
      actionMap = raw;
    } else if (raw != null && raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) actionMap = decoded;
      } catch (_) {}
    }

    return NotificationInner1Data(
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      data: ActionData.fromJson(actionMap),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'data': data.toJson(),
  };
}

class ActionData {
  final int? action;
  final int? actionId;
  final int? laSubjectId;
  final int? laLevelId;
  final int? missionId;
  final int? visionId;
  final int? time; // <-- fix: added
  final String? visionTitle;

  ActionData({
    this.action,
    this.actionId,
    this.laSubjectId,
    this.laLevelId,
    this.missionId,
    this.visionId,
    this.time, // <-- fix
    this.visionTitle,
  });

  factory ActionData.fromJson(Map<String, dynamic> json) {
    return ActionData(
      action: json['action'] as int?,
      actionId: json['action_id'] ?? json['actionId'],
      laSubjectId: json['la_subject_id'] ?? json['laSubjectId'],
      laLevelId: json['la_level_id'] ?? json['laLevelId'],
      missionId: json['mission_id'] ?? json['missionId'],
      visionId: json['vision_id'] ?? json['visionId'],
      time: json['time'] ?? json['quiz_time'],
      visionTitle: json['vision_title'] ?? json['visionTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'action_id': actionId,
    'la_subject_id': laSubjectId,
    'la_level_id': laLevelId,
    'mission_id': missionId,
    'vision_id': visionId,
    'time': time,
    'vision_title': visionTitle,
  };
}
