import '../../domain/entities/comment_entity.dart';

/// Data model for CommentEntity with JSON serialization
///
/// This model handles conversion between CommentEntity and JSON for
/// Firebase Firestore storage and network transmission.
class CommentModel extends CommentEntity {
  CommentModel({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    int likesCount = 0,
    List<String> likedByUserIds = const [],
    bool isReported = false,
  }) : super(
          id: id,
          postId: postId,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          content: content,
          createdAt: createdAt,
          updatedAt: updatedAt,
          likesCount: likesCount,
          likedByUserIds: likedByUserIds,
          isReported: isReported,
        );

  /// Convert from CommentEntity
  factory CommentModel.fromEntity(CommentEntity entity) {
    return CommentModel(
      id: entity.id,
      postId: entity.postId,
      userId: entity.userId,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      likesCount: entity.likesCount,
      likedByUserIds: entity.likedByUserIds,
      isReported: entity.isReported,
    );
  }

  /// Convert to CommentEntity
  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likesCount: likesCount,
      likedByUserIds: likedByUserIds,
      isReported: isReported,
    );
  }

  /// Create from Firestore document
  factory CommentModel.fromJson(Map<String, dynamic> json, String id) {
    return CommentModel(
      id: id,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      likesCount: json['likesCount'] as int? ?? 0,
      likedByUserIds: (json['likedByUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isReported: json['isReported'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likesCount': likesCount,
      'likedByUserIds': likedByUserIds,
      'isReported': isReported,
    };
  }
}
