import '../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

abstract class CommunityRepositoryInterface {
  Future<Result<List<PostEntity>>> getPosts(
      {int limit = 20, String? lastPostId});

  Future<Result<PostEntity>> createPost({
    required String content,
    required String userId,
    required String username,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  });

  Future<Result<void>> toggleLikePost(
      {required String postId, required String userId});

  Future<Result<List<CommentEntity>>> getComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  });

  Future<Result<CommentEntity>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
  });
}
