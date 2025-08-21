class PblTextbookMappingResponse {
  final int status;
  final PblTextbookMappingData data;
  final String message;

  PblTextbookMappingResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory PblTextbookMappingResponse.fromJson(Map<String, dynamic> json) {
    return PblTextbookMappingResponse(
      status: json['status'] ?? 0,
      data: PblTextbookMappingData.fromJson(json['data']),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toJson(),
      'message': message,
    };
  }
}

class PblTextbookMappingData {
  final List<PblTextbookMapping> pblTextbookMappings;

  PblTextbookMappingData({required this.pblTextbookMappings});

  factory PblTextbookMappingData.fromJson(Map<String, dynamic> json) {
    return PblTextbookMappingData(
      pblTextbookMappings: (json['pbl_textbook_mappings'] as List)
          .map((e) => PblTextbookMapping.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pbl_textbook_mappings':
      pblTextbookMappings.map((e) => e.toJson()).toList(),
    };
  }
}

class PblTextbookMapping {
  final int id;
  final Language language;
  final Board board;
  final Subject subject;
  final Grade grade;
  final String title;
  final Document document;

  PblTextbookMapping({
    required this.id,
    required this.language,
    required this.board,
    required this.subject,
    required this.grade,
    required this.title,
    required this.document,
  });

  factory PblTextbookMapping.fromJson(Map<String, dynamic> json) {
    return PblTextbookMapping(
      id: json['id'] ?? 0,
      language: Language.fromJson(json['language']),
      board: Board.fromJson(json['board']),
      subject: Subject.fromJson(json['subject']),
      grade: Grade.fromJson(json['grade']),
      title: json['title'] ?? '',
      document: Document.fromJson(json['document']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language.toJson(),
      'board': board.toJson(),
      'subject': subject.toJson(),
      'grade': grade.toJson(),
      'title': title,
      'document': document.toJson(),
    };
  }
}

class Language {
  final int id;
  final String name;

  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Board {
  final int id;
  final String name;

  Board({required this.id, required this.name});

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Subject {
  final int id;
  final String title;
  final String heading;
  final String metaTitle;
  final SubjectImage image;
  final bool isCouponAvailable;
  final bool couponCodeUnlock;

  Subject({
    required this.id,
    required this.title,
    required this.heading,
    required this.metaTitle,
    required this.image,
    required this.isCouponAvailable,
    required this.couponCodeUnlock,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      heading: json['heading'] ?? '',
      metaTitle: json['meta_title'] ?? '',
      image: SubjectImage.fromJson(json['image']),
      isCouponAvailable: json['is_coupon_available'] ?? false,
      couponCodeUnlock: json['coupon_code_unlock'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'heading': heading,
      'meta_title': metaTitle,
      'image': image.toJson(),
      'is_coupon_available': isCouponAvailable,
      'coupon_code_unlock': couponCodeUnlock,
    };
  }
}

class SubjectImage {
  final int id;
  final String name;
  final String url;

  SubjectImage({required this.id, required this.name, required this.url});

  factory SubjectImage.fromJson(Map<String, dynamic> json) {
    return SubjectImage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}

class Grade {
  final int id;
  final String name;

  Grade({required this.id, required this.name});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Document {
  final int id;
  final String name;
  final String url;

  Document({required this.id, required this.name, required this.url});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}
