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
  final String categoryKey; // normalized key (e.g., "coins", "profile")
  final String categoryName; // original display name from API

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

/// Represents a UI category (purely API-driven)
class TeacherFaqCategory {
  final String key; // normalized key
  final String name; // display name from API
  final List<TeacherFaq> faqItems; // FAQs in this category

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
