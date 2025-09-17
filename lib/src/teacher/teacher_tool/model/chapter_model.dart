class Chapter {
  final int id;
  final String title;
  final int laBoardId;
  final int laGradeId;
  final int? laSubjectId;

  Chapter({
    required this.id,
    required this.title,
    required this.laBoardId,
    required this.laGradeId,
    this.laSubjectId,
  });

  // From JSON
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      title: json['title'],
      laBoardId: json['la_board_id'],
      laGradeId: json['la_grade_id'],
      laSubjectId: json['la_subject_id'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'la_board_id': laBoardId,
      'la_grade_id': laGradeId,
      'la_subject_id': laSubjectId,
    };
  }
}
