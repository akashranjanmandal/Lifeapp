// lib/src/student/home/models/faq_category_model.dart

/// Normalizes API category names to a consistent key used in UI.
/// e.g. "Coin" -> "coins", "Profile" -> "profile", "Mission Control" -> "mission-control"
String _normalizeCategoryKey(String name) {
  final n = (name ?? '').trim().toLowerCase();
  if (n == 'coin') return 'coins'; // unify singular/plural
  return n.replaceAll(' ', '-');
}

/// Represents one FAQ entry parsed from API
class Faq {
  final int id;
  final String question;
  final String answer;
  final String audience; // "student" | "teacher" | "all"
  final String categoryKey; // normalized key (e.g., "coins", "profile")
  final String categoryName; // original display name from API

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.audience,
    required this.categoryKey,
    required this.categoryName,
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    final catName = (json['category']?['name'] ?? '').toString();
    final key = _normalizeCategoryKey(catName);

    return Faq(
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
class FaqCategory {
  final String key; // normalized key (e.g., "coins")
  final String name; // display ("Coins")
  final String icon; // emoji
  final List<Faq> faqItems; // FAQs for this category (can be empty)

  FaqCategory({
    required this.key,
    required this.name,
    required this.icon,
    this.faqItems = const [],
  });

  FaqCategory copyWith({List<Faq>? faqItems}) => FaqCategory(
        key: key,
        name: name,
        icon: icon,
        faqItems: faqItems ?? this.faqItems,
      );
}

// Icon map for categories you always show
const Map<String, String> _kCategoryIcons = {
  'coins': '💰',
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

final List<FaqCategory> predefinedCategories = _kCategoryIcons.entries
    .map((e) => FaqCategory(key: e.key, name: _titleCase(e.key), icon: e.value))
    .toList();
