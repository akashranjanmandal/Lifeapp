// models/pbl_language_model.dart
class PblLanguageModel {
  final int status;
  final PblLanguageData data;
  final String message;

  PblLanguageModel({
    required this.status,
    required this.data,
    required this.message,
  });

  factory PblLanguageModel.fromJson(Map<String, dynamic> json) {
    return PblLanguageModel(
      status: json['status'] ?? 0,
      data: PblLanguageData.fromJson(json['data'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class PblLanguageData {
  final List<PblLanguageItem> pblLanguages;

  PblLanguageData({
    required this.pblLanguages,
  });

  factory PblLanguageData.fromJson(Map<String, dynamic> json) {
    return PblLanguageData(
      pblLanguages: (json['languages'] as List? ?? [])
          .map((item) => PblLanguageItem.fromJson(item))
          .toList(),
    );
  }
}

class PblLanguageItem {
  final int? pblLangId;
  final String? pblLangName;
  final String? pblLangTitle;
  final String? pblLangSlug;

  PblLanguageItem({
    this.pblLangId,
    this.pblLangName,
    this.pblLangTitle,
    this.pblLangSlug,
  });

  factory PblLanguageItem.fromJson(Map<String, dynamic> json) {
    return PblLanguageItem(
      pblLangId: json['id'],
      pblLangName: json['name'],
      pblLangTitle: json['title'],
      pblLangSlug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': pblLangId,
      'name': pblLangName,
      'title': pblLangTitle,
      'slug': pblLangSlug,
    };
  }
}