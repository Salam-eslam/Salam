class ChatSession {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromSupabase(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'title': title,
    };
  }
}
