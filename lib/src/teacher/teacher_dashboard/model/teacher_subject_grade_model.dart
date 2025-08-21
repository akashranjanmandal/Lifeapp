class TeacherSubjectGradeModel {
  bool? success;
  String? message;
  List<dynamic>? subjectGradePairsRaw; // raw JSON array

  TeacherSubjectGradeModel({this.success, this.message, this.subjectGradePairsRaw});

  TeacherSubjectGradeModel.fromJson(Map<String, dynamic> json) {
    success = json['status']; // API uses "status"
    message = json['message'];
    subjectGradePairsRaw = json['subject_grade_pairs'];
  }

  // Getter to convert raw JSON to list of pairs
  List<TeacherSubjectGradePair> get subjectGradePairs {
    if (subjectGradePairsRaw == null) return [];
    return subjectGradePairsRaw!
        .map((e) => TeacherSubjectGradePair.fromJson(e))
        .toList();
  }
}

class TeacherSubjectGradePair {
  TeacherSubject? subject;
  TeacherGrade? grade;

  TeacherSubjectGradePair({this.subject, this.grade});

  TeacherSubjectGradePair.fromJson(Map<String, dynamic> json) {
    subject = TeacherSubject.fromJson({
      'subject_id': json['subject_id'],
      'subject_title': json['subject_title'],
      'subject_code': json['subject_code'],
    });

    grade = TeacherGrade.fromJson({
      'grade_id': json['grade_id'],
      'grade_name': json['grade_name'],
      'grade_code': json['grade_code'],
    });
  }

  Map<String, dynamic> toJson() => {
    'subject': subject?.toJson(),
    'grade': grade?.toJson(),
  };
}

class TeacherSubject {
  int? id;
  String? title;
  String? code;

  TeacherSubject({this.id, this.title, this.code});

  TeacherSubject.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? json['subject_id'];
    title = json['title'] ?? json['subject_title'];
    code = json['code'] ?? json['subject_code'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'code': code,
  };
}

class TeacherGrade {
  int? id;
  String? name;
  String? code;

  TeacherGrade({this.id, this.name, this.code});

  TeacherGrade.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? json['grade_id'];
    name = json['name'] ?? json['grade_name'];
    code = json['code'] ?? json['grade_code'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
  };
}
