/// Normalizes API category names to a consistent key used in UI.
String _normalizeCategoryKey(String name) {
  final n = (name).trim().toLowerCase();
  if (n == 'coin') return 'coins';
  return n.replaceAll(' ', '-');
}

class StudentFaq {
  final int id;
  final String question;
  final String answer;
  final String audience;
  final String categoryKey;
  final String categoryName;

  StudentFaq({
    required this.id,
    required this.question,
    required this.answer,
    required this.audience,
    required this.categoryKey,
    required this.categoryName,
  });

  factory StudentFaq.fromJson(Map<String, dynamic> json) {
    final catName = (json['category']?['name'] ?? '').toString();
    final key = _normalizeCategoryKey(catName);

    return StudentFaq(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      audience: (json['audience'] ?? 'student').toString().toLowerCase(),
      categoryKey: key,
      categoryName: catName.isEmpty ? key : catName,
    );
  }
}

class StudentFaqCategory {
  final String key;
  final String name;
  final List<StudentFaq> faqItems; // FAQs in this category

  StudentFaqCategory({
    required this.key,
    required this.name,
    this.faqItems = const [],
  });

  StudentFaqCategory copyWith({List<StudentFaq>? faqItems}) =>
      StudentFaqCategory(
        key: key,
        name: name,
        faqItems: faqItems ?? this.faqItems,
      );
}
