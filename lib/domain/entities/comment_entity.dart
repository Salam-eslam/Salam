/// Comment entity representing a user's comment on a community post
///
/// Comments allow users to engage in discussions about posts and
/// share additional insights or questions.
class CommentEntity {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final List<String> likedByUserIds;
  final bool isReported;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.likedByUserIds = const [],
    this.isReported = false,
  });

  CommentEntity copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedByUserIds,
    bool? isReported,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      isReported: isReported ?? this.isReported,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CommentEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
