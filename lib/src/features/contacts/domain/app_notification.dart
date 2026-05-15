class AppNotification {
  const AppNotification({
    required this.id,
    required this.code,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String code;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}
