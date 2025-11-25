import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/community_repository_interface.dart';
import '../datasources/community_remote_datasource.dart';

class CommunityRepository implements CommunityRepositoryInterface {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepository({required this.remoteDataSource});

  @override
  Future<Result<List<PostEntity>>> getPosts(
      {int limit = 20, String? lastPostId}) async {
    try {
      final result =
          await remoteDataSource.getPosts(limit: limit, lastPostId: lastPostId);
      return Success(result);
    } catch (e) {
      return ResultError(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<PostEntity>> createPost({
    required String content,
    required String userId,
    required String username,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  }) async {
    try {
      final result = await remoteDataSource.createPost(
        content: content,
        userId: userId,
        userName: username,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        verseText: verseText,
      );
      return Success(result);
    } catch (e) {
      return ResultError(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleLikePost(
      {required String postId, required String userId}) async {
    try {
      await remoteDataSource.toggleLikePost(postId: postId, userId: userId);
      return const Success(null);
    } catch (e) {
      return ResultError(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<CommentEntity>>> getComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  }) async {
    try {
      final result = await remoteDataSource.getComments(
        postId: postId,
        limit: limit,
        lastCommentId: lastCommentId,
      );
      return Success(result);
    } catch (e) {
      return ResultError(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<CommentEntity>> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
  }) async {
    try {
      final result = await remoteDataSource.createComment(
        postId: postId,
        userId: userId,
        userName: userName,
        content: content,
      );
      return Success(result);
    } catch (e) {
      return ResultError(ServerFailure(message: e.toString()));
    }
  }
}
