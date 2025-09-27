/// Normalizes API category names to a consistent key used in UI.
String _normalizeCategoryKey(String name) {
  final n = (name).trim().toLowerCase();
  if (n == 'coin') return 'coins';
  return n.replaceAll(' ', '-');
}

class TeacherFaq {
  final int id;
  final String question;
  final String answer;
  final String audience; // "student" | "teacher" | "all"
  final String categoryKey;
  final String categoryName;

  TeacherFaq({
    required this.id,
    required this.question,
    required this.answer,
    required this.audience,
    required this.categoryKey,
    required this.categoryName,
  });

  factory TeacherFaq.fromJson(Map<String, dynamic> json) {
    final catName = (json['category']?['name'] ?? '').toString();
    final key = _normalizeCategoryKey(catName);

    return TeacherFaq(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      audience: (json['audience'] ?? 'teacher').toString().toLowerCase(),
      categoryKey: key,
      categoryName: catName.isEmpty ? key : catName,
    );
  }
}

class TeacherFaqCategory {
  final String key;
  final String name;
  final List<TeacherFaq> faqItems;

  TeacherFaqCategory({
    required this.key,
    required this.name,
    this.faqItems = const [],
  });

  TeacherFaqCategory copyWith({List<TeacherFaq>? faqItems}) =>
      TeacherFaqCategory(
        key: key,
        name: name,
        faqItems: faqItems ?? this.faqItems,
      );
}
