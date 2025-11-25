import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<String> likedByUserIds;
  final bool isReported;
  final int? surahNumber;
  final int? verseNumber;
  final String? verseText;

  const PostEntity({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.likedByUserIds = const [],
    this.isReported = false,
    this.surahNumber,
    this.verseNumber,
    this.verseText,
  });

  PostEntity copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<String>? likedByUserIds,
    bool? isReported,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      isReported: isReported ?? this.isReported,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        userAvatar,
        content,
        createdAt,
        updatedAt,
        likesCount,
        commentsCount,
        isLiked,
        likedByUserIds,
        isReported,
        surahNumber,
        verseNumber,
        verseText,
      ];
}
