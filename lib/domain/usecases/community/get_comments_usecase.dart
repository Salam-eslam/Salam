import '../../entities/comment_entity.dart';
import '../../repositories/community_repository_interface.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

/// Use case for getting comments on a post
class GetCommentsUseCase {
  final CommunityRepositoryInterface repository;

  GetCommentsUseCase(this.repository);

  /// Execute the use case
  ///
  /// [postId] - ID of the post to get comments for
  /// [limit] - Number of comments to fetch (1-100, default: 50)
  /// [lastCommentId] - For pagination
  ///
  /// Returns Result<List<CommentEntity>> with comments or error
  Future<Result<List<CommentEntity>>> execute({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  }) async {
    // Validate post ID
    if (postId.trim().isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'Post ID cannot be empty'),
      );
    }

    // Validate limit
    if (limit < 1 || limit > 100) {
      return ResultError(
        InvalidInputFailure(
          message: 'Limit must be between 1 and 100',
        ),
      );
    }

    return await repository.getComments(
      postId: postId,
      limit: limit,
      lastCommentId: lastCommentId,
    );
  }
}
