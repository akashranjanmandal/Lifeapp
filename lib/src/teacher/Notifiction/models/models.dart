class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['data']['title'],
      message: json['data']['message'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
    );
  }

  bool get isUnread => readAt == null;
}
