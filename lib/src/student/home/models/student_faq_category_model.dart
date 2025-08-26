// student_faq_category_model.dart

String _normalizeCategoryKey(String name) {
  final n = (name ?? '').trim().toLowerCase();
  if (n == 'coin') return 'coins'; // unify singular/plural
  return n.replaceAll(' ', '-');
}

/// Represents one FAQ entry parsed from API
class StudentFaq {
  final int id;
  final String question;
  final String answer;
  final String audience; // "student" | "teacher" | "all"
  final String categoryKey; // normalized key (e.g., "coins", "profile")
  final String categoryName; // original display name from API

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
      audience: (json['audience'] ?? 'all').toString().toLowerCase(),
      categoryKey: key,
      categoryName: catName.isEmpty ? key : catName,
    );
  }
}

/// Represents a UI category (emoji icon + FAQs inside it)
class StudentFaqCategory {
  final String key; // normalized key
  final String name; // display name
  final String icon; // emoji icon
  final List<StudentFaq> faqItems; // FAQs for this category

  StudentFaqCategory({
    required this.key,
    required this.name,
    required this.icon,
    this.faqItems = const [],
  });

  StudentFaqCategory copyWith({List<StudentFaq>? faqItems}) =>
      StudentFaqCategory(
        key: key,
        name: name,
        icon: icon,
        faqItems: faqItems ?? this.faqItems,
      );
}

// Icon map for predefined student categories
const Map<String, String> _kStudentCategoryIcons = {
  'coins': '💰',
  'accessibility': '🧑‍🦽',
  'profile': '👤',
  'mission': '🚀',
  'vision': '🌟',
  'quiz': '❓',
};

// Helper to convert keys to title case
String _titleCase(String key) {
  return key
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// Predefined student categories for UI skeleton
final List<StudentFaqCategory> predefinedStudentCategories =
    _kStudentCategoryIcons.entries
        .map((e) => StudentFaqCategory(
              key: e.key,
              name: _titleCase(e.key),
              icon: e.value,
            ))
        .toList();
