// To parse this JSON data, do
//
//     final missionListModel = missionListModelFromJson(jsonString);

import 'dart:convert';

MissionListModel missionListModelFromJson(String str) => MissionListModel.fromJson(json.decode(str));

String missionListModelToJson(MissionListModel data) => json.encode(data.toJson());

class MissionListModel {
  int? status;
  Data? data;
  String? message;
  MissionListModel({
    this.status,
    this.data,
    this.message,
  });

  factory MissionListModel.fromJson(Map<String, dynamic> json) => MissionListModel(
    status: _safeParseInt(json["status"]),
    data: json["data"] is Map<String, dynamic> ? Data.fromJson(json["data"] as Map<String, dynamic>) : null,
    message: _safeParseString(json["message"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data?.toJson(),
    "message": message,
  };
}

class Data {
  Missions? missions;

  Data({
    this.missions,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    missions: json["missions"] is Map<String, dynamic> ? Missions.fromJson(json["missions"] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    "missions": missions?.toJson(),
  };
}

class Missions {
  List<MissionDatum>? data;
  Links? links;
  Meta? meta;

  Missions({
    this.data,
    this.links,
    this.meta,
  });

  factory Missions.fromJson(Map<String, dynamic> json) => Missions(
    data: json["data"] is List
        ? List<MissionDatum>.from((json["data"] as List).map((x) => MissionDatum.fromJson(x as Map<String, dynamic>)))
        : [],
    links: json["links"] is Map<String, dynamic> ? Links.fromJson(json["links"] as Map<String, dynamic>) : null,
    meta: json["meta"] is Map<String, dynamic> ? Meta.fromJson(json["meta"] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "links": links?.toJson(),
    "meta": meta?.toJson(),
  };
}

class MissionDatum {
  int? id;
  Level? level;
  List<dynamic>? topic;
  int? type;
  String? title;
  String? description;
  Document? image;
  Document? document;
  String? question;
  Subject? subject;
  List<Resource>? resources;
  Submission? submission;
  dynamic assignedBy;
  String? status;

  MissionDatum({
    this.id,
    this.level,
    this.topic,
    this.type,
    this.title,
    this.description,
    this.image,
    this.document,
    this.question,
    this.subject,
    this.resources,
    this.submission,
    this.assignedBy,
    this.status,
  });

  factory MissionDatum.fromJson(Map<String, dynamic> json) => MissionDatum(
    id: _safeParseInt(json["id"]),
    level: json["level"] is Map<String, dynamic> ? Level.fromJson(json["level"] as Map<String, dynamic>) : null,
    topic: json["topic"] is List ? List<dynamic>.from(json["topic"] as List) : [],
    type: _safeParseInt(json["type"]),
    title: _safeParseString(json["title"]),
    description: _safeParseString(json["description"]),
    image: json["image"] is Map<String, dynamic> ? Document.fromJson(json["image"] as Map<String, dynamic>) : null,
    document: json["document"] is Map<String, dynamic> ? Document.fromJson(json["document"] as Map<String, dynamic>) : null,
    question: _safeParseString(json["question"]),
    subject: json["subject"] is Map<String, dynamic> ? Subject.fromJson(json["subject"] as Map<String, dynamic>) : null,
    resources: json["resources"] is List
        ? List<Resource>.from((json["resources"] as List).map((x) => Resource.fromJson(x as Map<String, dynamic>)))
        : [],
    submission: _parseSubmission(json["submission"]),
    assignedBy: json["assigned_by"],
    status: _safeParseString(json["status"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "level": level?.toJson(),
    "topic": topic == null ? [] : List<dynamic>.from(topic!.map((x) => x)),
    "type": type,
    "title": title,
    "description": description,
    "image": image?.toJson(),
    "document": document?.toJson(),
    "question": question,
    "subject": subject?.toJson(),
    "resources": resources == null ? [] : List<dynamic>.from(resources!.map((x) => x.toJson())),
    "submission": submission?.toJson(),
    "assigned_by": assignedBy,
    "status": status,
  };

  static Submission? _parseSubmission(dynamic submissionData) {
    if (submissionData == null) return null;

    try {
      if (submissionData is List) {
        if (submissionData.isNotEmpty) {
          final firstItem = submissionData[0];
          if (firstItem is Map<String, dynamic>) {
            return Submission.fromJson(firstItem);
          }
        }
        return null;
      }

      if (submissionData is Map<String, dynamic>) {
        return Submission.fromJson(submissionData);
      }

      return null;
    } catch (e) {
      print('Error parsing submission data: $e');
      print('Submission data: $submissionData');
      return null;
    }
  }
}

class Document {
  int? id;
  String? name;
  String? url;

  Document({
    this.id,
    this.name,
    this.url,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: _safeParseInt(json["id"]),
    name: _safeParseString(json["name"]),
    url: _safeParseString(json["url"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
  };
}

class Level {
  int? id;
  String? title;
  dynamic description;
  int? missionPoints;
  int? quizPoints;
  int? riddlePoints;
  int? puzzlePoints;
  int? jigyasaPoints;
  int? pragyaPoints;
  int? quizTime;
  int? riddleTime;
  int? puzzleTime;

  Level({
    this.id,
    this.title,
    this.description,
    this.missionPoints,
    this.quizPoints,
    this.riddlePoints,
    this.puzzlePoints,
    this.jigyasaPoints,
    this.pragyaPoints,
    this.quizTime,
    this.riddleTime,
    this.puzzleTime,
  });

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    id: _safeParseInt(json["id"]),
    title: _safeParseString(json["title"]),
    description: json["description"],
    missionPoints: _safeParseInt(json["mission_points"]),
    quizPoints: _safeParseInt(json["quiz_points"]),
    riddlePoints: _safeParseInt(json["riddle_points"]),
    puzzlePoints: _safeParseInt(json["puzzle_points"]),
    jigyasaPoints: _safeParseInt(json["jigyasa_points"]),
    pragyaPoints: _safeParseInt(json["pragya_points"]),
    quizTime: _safeParseInt(json["quiz_time"]),
    riddleTime: _safeParseInt(json["riddle_time"]),
    puzzleTime: _safeParseInt(json["puzzle_time"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "mission_points": missionPoints,
    "quiz_points": quizPoints,
    "riddle_points": riddlePoints,
    "puzzle_points": puzzlePoints,
    "jigyasa_points": jigyasaPoints,
    "pragya_points": pragyaPoints,
    "quiz_time": quizTime,
    "riddle_time": riddleTime,
    "puzzle_time": puzzleTime,
  };
}

class Resource {
  int? id;
  String? title;
  Document? media;
  String? locale;

  Resource({
    this.id,
    this.title,
    this.media,
    this.locale,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    id: _safeParseInt(json["id"]),
    title: _safeParseString(json["title"]),
    media: json["media"] is Map<String, dynamic> ? Document.fromJson(json["media"] as Map<String, dynamic>) : null,
    locale: _safeParseString(json["locale"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "media": media?.toJson(),
    "locale": locale,
  };
}

class Subject {
  int? id;
  String? title;
  String? heading;
  Document? image;
  bool? isCouponAvailable;
  bool? couponCodeUnlock;

  Subject({
    this.id,
    this.title,
    this.heading,
    this.image,
    this.isCouponAvailable,
    this.couponCodeUnlock,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: _safeParseInt(json["id"]),
    title: _safeParseString(json["title"]),
    heading: _safeParseString(json["heading"]),
    image: json["image"] is Map<String, dynamic> ? Document.fromJson(json["image"] as Map<String, dynamic>) : null,
    isCouponAvailable: _safeParseBool(json["is_coupon_available"]),
    couponCodeUnlock: _safeParseBool(json["coupon_code_unlock"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "heading": heading,
    "image": image?.toJson(),
    "is_coupon_available": isCouponAvailable,
    "coupon_code_unlock": couponCodeUnlock,
  };
}

class Submission {
  int? id;
  User? user;
  dynamic title;
  Document? media;
  String? description;
  String? comments;
  dynamic approvedAt;
  DateTime? rejectedAt;
  int? points;
  int? timing;

  Submission({
    this.id,
    this.user,
    this.title,
    this.media,
    this.description,
    this.comments,
    this.approvedAt,
    this.rejectedAt,
    this.points,
    this.timing,
  });

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
    id: _safeParseInt(json["id"]),
    user: json["user"] is Map<String, dynamic> ? User.fromJson(json["user"] as Map<String, dynamic>) : null,
    title: json["title"],
    media: json["media"] is Map<String, dynamic> ? Document.fromJson(json["media"] as Map<String, dynamic>) : null,
    description: _safeParseString(json["description"]),
    comments: _safeParseString(json["comments"]),
    approvedAt: json["approved_at"],
    rejectedAt: json["rejected_at"] is String ? DateTime.tryParse(json["rejected_at"] as String) : null,
    points: _safeParseInt(json["points"]),
    timing: _safeParseInt(json["timing"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user": user?.toJson(),
    "title": title,
    "media": media?.toJson(),
    "description": description,
    "comments": comments,
    "approved_at": approvedAt,
    "rejected_at": rejectedAt?.toIso8601String(),
    "points": points,
    "timing": timing,
  };
}

class User {
  int? id;
  String? name;
  dynamic email;
  String? mobileNo;
  dynamic username;
  School? school;
  String? state;
  String? profileImage;

  User({
    this.id,
    this.name,
    this.email,
    this.mobileNo,
    this.username,
    this.school,
    this.state,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: _safeParseInt(json["id"]),
    name: _safeParseString(json["name"]),
    email: json["email"],
    mobileNo: _safeParseString(json["mobile_no"]),
    username: json["username"],
    school: json["school"] is Map<String, dynamic> ? School.fromJson(json["school"] as Map<String, dynamic>) : null,
    state: _safeParseString(json["state"]),
    profileImage: _safeParseString(json["profile_image"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "mobile_no": mobileNo,
    "username": username,
    "school": school?.toJson(),
    "state": state,
    "profile_image": profileImage,
  };
}

class School {
  int? id;
  String? name;
  String? state;
  String? city;

  School({
    this.id,
    this.name,
    this.state,
    this.city,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
    id: _safeParseInt(json["id"]),
    name: _safeParseString(json["name"]),
    state: _safeParseString(json["state"]),
    city: _safeParseString(json["city"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "state": state,
    "city": city,
  };
}

class Links {
  String? first;
  String? last;
  dynamic prev;
  dynamic next;

  Links({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    first: _safeParseString(json["first"]),
    last: _safeParseString(json["last"]),
    prev: json["prev"],
    next: json["next"],
  );

  Map<String, dynamic> toJson() => {
    "first": first,
    "last": last,
    "prev": prev,
    "next": next,
  };
}

class Meta {
  int? currentPage;
  int? from;
  int? lastPage;
  List<Link>? links;
  String? path;
  int? perPage;
  int? to;
  int? total;

  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.links,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    currentPage: _safeParseInt(json["current_page"]),
    from: _safeParseInt(json["from"]),
    lastPage: _safeParseInt(json["last_page"]),
    links: json["links"] is List
        ? List<Link>.from((json["links"] as List).map((x) => Link.fromJson(x as Map<String, dynamic>)))
        : [],
    path: _safeParseString(json["path"]),
    perPage: _safeParseInt(json["per_page"]),
    to: _safeParseInt(json["to"]),
    total: _safeParseInt(json["total"]),
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "from": from,
    "last_page": lastPage,
    "links": links == null ? [] : List<dynamic>.from(links!.map((x) => x.toJson())),
    "path": path,
    "per_page": perPage,
    "to": to,
    "total": total,
  };
}

class Link {
  String? url;
  String? label;
  bool? active;

  Link({
    this.url,
    this.label,
    this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
    url: _safeParseString(json["url"]),
    label: _safeParseString(json["label"]),
    active: _safeParseBool(json["active"]),
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "label": label,
    "active": active,
  };
}

// Helper functions for safe parsing
int? _safeParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

String? _safeParseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool? _safeParseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value == 1;
  return null;
}