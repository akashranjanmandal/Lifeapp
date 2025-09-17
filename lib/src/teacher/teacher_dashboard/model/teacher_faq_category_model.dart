/// Normalizes API category names to a consistent key used in UI.
String _normalizeCategoryKey(String name) {
  final n = (name ?? '').trim().toLowerCase();
  if (n == 'coin') return 'coins';
  return n.replaceAll(' ', '-');
}

class TeacherFaq {
  final int id;
  final String question;
  final String answer;
  final String
      audience; // "student" | "teacher" | "all" (we only use "teacher")
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

/// Represents a UI category (emoji icon + FAQs inside it)
class TeacherFaqCategory {
  final String key; // normalized key (e.g., "coins")
  final String name; // display properties
  final String icon; // logo
  final List<TeacherFaq> faqItems; // FAQs for this category (can be empty)

  TeacherFaqCategory({
    required this.key,
    required this.name,
    required this.icon,
    this.faqItems = const [],
  });

  TeacherFaqCategory copyWith({List<TeacherFaq>? faqItems}) =>
      TeacherFaqCategory(
        key: key,
        name: name,
        icon: icon,
        faqItems: faqItems ?? this.faqItems,
      );
}

// Icon map for always showing either asset or temp emoji
const Map<String, String> _kTeacherCategoryIcons = {
  'coins': 'assets/images/coins_icon.png',
  'accessibility': '🧑‍🦽',
  'profile': '👤',
  'mission': '🚀',
  'vision': '🌟',
  'quiz': '❓',
};

// Build the predefined category skeleton (always shown in list)
String _titleCase(String key) {
  return key
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

final List<TeacherFaqCategory> predefinedTeacherCategories =
    _kTeacherCategoryIcons.entries
        .map((e) => TeacherFaqCategory(
              key: e.key,
              name: _titleCase(e.key),
              icon: e.value,
            ))
        .toList();
