// To parse this JSON data, do
//
//     final teacherMissonParticipantModel = teacherMissonParticipantModelFromJson(jsonString);

import 'dart:convert';
List<dynamic> _parseDocument(dynamic documentData) {
  if (documentData == null) return [];

  if (documentData is List) {
    return List<dynamic>.from(documentData);
  } else if (documentData is Map) {
    return documentData.values.toList();
  } else {
    return [documentData];
  }
}
TeacherMissionParticipantModel teacherMissionParticipantModelFromJson(String str) => TeacherMissionParticipantModel.fromJson(json.decode(str));

String teacherMissionParticipantModelToJson(TeacherMissionParticipantModel data) => json.encode(data.toJson());

class TeacherMissionParticipantModel {
  int? status;
  Data? data;
  String? message;

  TeacherMissionParticipantModel({
    this.status,
    this.data,
    this.message,
  });

  factory TeacherMissionParticipantModel.fromJson(Map<String, dynamic> json) => TeacherMissionParticipantModel(
    status: json["status"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data?.toJson(),
    "message": message,
  };
}

class Data {
  List<Datum>? data;
  Links? links;
  Meta? meta;

  Data({
    this.data,
    this.links,
    this.meta,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    links: json["links"] == null ? null : Links.fromJson(json["links"]),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "links": links?.toJson(),
    "meta": meta?.toJson(),
  };
}

class Datum {
  int? id;
  Teacher? teacher;
  User? user;
  LaMission? laMission;
  String? dueDate;
  int? type;
  Submission? submission;

  Datum({
    this.id,
    this.teacher,
    this.user,
    this.laMission,
    this.dueDate,
    this.type,
    this.submission,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    teacher: json["teacher"] == null ? null : Teacher.fromJson(json["teacher"]),
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    laMission: json["la_mission"] == null ? null : LaMission.fromJson(json["la_mission"]),
    dueDate: json["due_date"],
    type: json["type"],
    submission: json["submission"] == null ? null : Submission.fromJson(json["submission"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "teacher": teacher?.toJson(),
    "user": user?.toJson(),
    "la_mission": laMission?.toJson(),
    "due_date": dueDate,
    "type": type,
    "submission": submission?.toJson(),
  };
}

class Teacher {
  int? id;
  String? name;
  dynamic email;
  String? mobileNo;
  dynamic username;
  School? school;
  String? state;
  String? profileImage;
  Section? section;
  Grade? grade;

  Teacher({
    this.id,
    this.name,
    this.email,
    this.mobileNo,
    this.username,
    this.school,
    this.state,
    this.profileImage,
    this.section,
    this.grade,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    mobileNo: json["mobile_no"],
    username: json["username"],
    school: json["school"] == null ? null : School.fromJson(json["school"]),
    state: json["state"],
    profileImage: json["profile_image"],
    section: json["section"] == null ? null : Section.fromJson(json["section"]),
    grade: json["grade"] == null ? null : Grade.fromJson(json["grade"]),
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
    "section": section?.toJson(),
    "grade": grade?.toJson(),
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
  Section? section;
  Grade? grade;

  User({
    this.id,
    this.name,
    this.email,
    this.mobileNo,
    this.username,
    this.school,
    this.state,
    this.profileImage,
    this.section,
    this.grade,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    mobileNo: json["mobile_no"],
    username: json["username"],
    school: json["school"] == null ? null : School.fromJson(json["school"]),
    state: json["state"],
    profileImage: json["profile_image"],
    section: json["section"] == null ? null : Section.fromJson(json["section"]),
    grade: json["grade"] == null ? null : Grade.fromJson(json["grade"]),
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
    "section": section?.toJson(),
    "grade": grade?.toJson(),
  };
}

class Grade {
  int? id;
  String? name;

  Grade({
    this.id,
    this.name,
  });

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

class Section {
  int? id;
  String? name;

  Section({
    this.id,
    this.name,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
  };
}

class School {
  int? id;
  String? name;
  String? state;
  String? city;
  int? code;

  School({
    this.id,
    this.name,
    this.state,
    this.city,
    this.code,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
    id: json["id"],
    name: json["name"],
    state: json["state"],
    city: json["city"],
    code: json["code"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "state": state,
    "city": city,
    "code": code,
  };
}

class LaMission {
  int? id;
  Title? title;
  Description? description;
  MissionImage? image; // ✅ CHANGED: Image → MissionImage
  int? laSubjectId;
  List<dynamic>? document;
  Question? question;
  int? status;
  int? index;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? laLevelId;
  int? type;
  int? allowFor;
  String? defaultTitle;

  LaMission({
    this.id,
    this.title,
    this.description,
    this.image,
    this.laSubjectId,
    this.document,
    this.question,
    this.status,
    this.index,
    this.createdAt,
    this.updatedAt,
    this.laLevelId,
    this.type,
    this.allowFor,
    this.defaultTitle,
  });

  factory LaMission.fromJson(Map<String, dynamic> json) => LaMission(
    id: json["id"],
    title: json["title"] == null ? null : Title.fromJson(json["title"]),
    description: json["description"] == null ? null : Description.fromJson(json["description"]),
    image: json["image"] == null ? null : MissionImage.fromJson(json["image"]), // ✅ UPDATED
    laSubjectId: json["la_subject_id"],
    document: json["document"] == null ? [] : _parseDocument(json["document"]),
    question: json["question"] == null ? null : Question.fromJson(json["question"]),
    status: json["status"],
    index: json["index"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    laLevelId: json["la_level_id"],
    type: json["type"],
    allowFor: json["allow_for"],
    defaultTitle: json["default_title"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title?.toJson(),
    "description": description?.toJson(),
    "image": image?.toJson(),
    "la_subject_id": laSubjectId,
    "document": document == null ? [] : List<dynamic>.from(document!.map((x) => x)),
    "question": question?.toJson(),
    "status": status,
    "index": index,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "la_level_id": laLevelId,
    "type": type,
    "allow_for": allowFor,
    "default_title": defaultTitle,
  };
}

class Description {
  String? en;

  Description({
    this.en,
  });

  factory Description.fromJson(Map<String, dynamic> json) => Description(
    en: json["en"],
  );

  Map<String, dynamic> toJson() => {
    "en": en,
  };
}

class MissionImage {
  String? en;

  MissionImage({
    this.en,
  });

  factory MissionImage.fromJson(Map<String, dynamic> json) => MissionImage(
    en: json["en"]?.toString(), // ✅ Convert any type to string
  );

  Map<String, dynamic> toJson() => {
    "en": en,
  };
}

class Question {
  String? en;

  Question({
    this.en,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    en: json["en"],
  );

  Map<String, dynamic> toJson() => {
    "en": en,
  };
}

class Title {
  String? en;

  Title({
    this.en,
  });

  factory Title.fromJson(Map<String, dynamic> json) => Title(
    en: json["en"],
  );

  Map<String, dynamic> toJson() => {
    "en": en,
  };
}

class Submission {
  int? id;
  User? user;
  String? missionTitle;
  List<Media>? media;
  String? description;
  String? comments;
  dynamic approvedAt;
  dynamic rejectedAt;
  int? points;
  dynamic timing;

  Submission({
    this.id,
    this.user,
    this.missionTitle,
    this.media,
    this.description,
    this.comments,
    this.approvedAt,
    this.rejectedAt,
    this.points,
    this.timing,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    List<Media> mediaList = [];

    if (json["media"] != null) {
      if (json["media"] is List) {
        // ✅ API gives a list of media
        mediaList = (json["media"] as List)
            .map((x) => Media.fromJson(x))
            .toList();
      } else if (json["media"] is Map) {
        // ✅ API gives a single media object
        mediaList = [Media.fromJson(json["media"])];
      }
    }

    return Submission(
      id: json["id"],
      user: json["user"] == null ? null : User.fromJson(json["user"]),
      missionTitle: json["mission_title"],
      media: mediaList, // ✅ always a List<Media>
      description: json["description"],
      comments: json["comments"],
      approvedAt: json["approved_at"],
      rejectedAt: json["rejected_at"],
      points: json["points"],
      timing: json["timing"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user": user?.toJson(),
    "mission_title": missionTitle,
    "media": media == null
        ? []
        : media!.map((x) => x.toJson()).toList(),
    "description": description,
    "comments": comments,
    "approved_at": approvedAt,
    "rejected_at": rejectedAt,
    "points": points,
    "timing": timing,
  };
}

class Media {
  int? id;
  String? name;
  String? url;

  Media({
    this.id,
    this.name,
    this.url,
  });

  factory Media.fromJson(Map<String, dynamic> json) => Media(
    id: json["id"],
    name: json["name"],
    url: json["url"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
  };
}

// ✅ ADDED: This is the Image class that was causing the conflict
class Image {
  int? id;
  String? name;
  String? path;
  String? type;
  int? imageableId;
  String? imageableType;
  DateTime? createdAt;
  DateTime? updatedAt;

  Image({
    this.id,
    this.name,
    this.path,
    this.type,
    this.imageableId,
    this.imageableType,
    this.createdAt,
    this.updatedAt,
  });

  factory Image.fromJson(Map<String, dynamic> json) => Image(
    id: json["id"],
    name: json["name"],
    path: json["path"],
    type: json["type"],
    imageableId: json["imageable_id"],
    imageableType: json["imageable_type"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "path": path,
    "type": type,
    "imageable_id": imageableId,
    "imageable_type": imageableType,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class Links {
  String? first;
  String? last;
  dynamic prev;
  String? next;

  Links({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory Links.fromJson(Map<String, dynamic> json) => Links(
    first: json["first"],
    last: json["last"],
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
    currentPage: json["current_page"],
    from: json["from"],
    lastPage: json["last_page"],
    links: json["links"] == null ? [] : List<Link>.from(json["links"]!.map((x) => Link.fromJson(x))),
    path: json["path"],
    perPage: json["per_page"],
    to: json["to"],
    total: json["total"],
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
    url: json["url"],
    label: json["label"],
    active: json["active"],
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "label": label,
    "active": active,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}

class SubmitMissionResponse {
  bool? success;
  SubmitMissionData? data;
  String? message;

  SubmitMissionResponse({
    this.success,
    this.data,
    this.message,
  });

  factory SubmitMissionResponse.fromJson(Map<String, dynamic> json) => SubmitMissionResponse(
    success: json["success"],
    data: json["data"] == null ? null : SubmitMissionData.fromJson(json["data"]),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data?.toJson(),
    "message": message,
  };
}

class SubmitMissionData {
  int? submitMissionId;
  int? allocatedCoins;
  int? teacherCoins;
  String? status;

  SubmitMissionData({
    this.submitMissionId,
    this.allocatedCoins,
    this.teacherCoins,
    this.status,
  });

  factory SubmitMissionData.fromJson(Map<String, dynamic> json) => SubmitMissionData(
    submitMissionId: json["submit_mission_id"],
    allocatedCoins: json["allocated_coins"],
    teacherCoins: json["teacher_coins"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "submit_mission_id": submitMissionId,
    "allocated_coins": allocatedCoins,
    "teacher_coins": teacherCoins,
    "status": status,
  };
}