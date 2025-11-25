class ChatMessage {
  final String? id;
  final String? sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool shouldShowIftaLink;

  ChatMessage({
    this.id,
    this.sessionId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.shouldShowIftaLink = false,
  });

  // Convert to/from Map for Hive storage (Legacy/Offline backup)
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isError': isError,
      'shouldShowIftaLink': shouldShowIftaLink,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sessionId: json['sessionId'] as String?,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isError: json['isError'] as bool? ?? false,
      shouldShowIftaLink: json['shouldShowIftaLink'] as bool? ?? false,
    );
  }

  // Supabase conversion
  Map<String, dynamic> toSupabase(String userId) {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'content': text,
      'is_user': isUser,
      'is_error': isError,
      'should_show_ifta_link': shouldShowIftaLink,
      'created_at': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromSupabase(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String?,
      text: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['created_at'] as String).toLocal(),
      isError: json['is_error'] as bool? ?? false,
      shouldShowIftaLink: json['should_show_ifta_link'] as bool? ?? false,
    );
  }
}
